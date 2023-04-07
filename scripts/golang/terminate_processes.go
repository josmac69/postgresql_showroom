/*
Check / terminate postgresql processes
Lately we had problems with long running processes blocking other processes. So I created following golang program which is able to check processes based on specified config file.
*/

package main

import (
    "database/sql"
    "flag"
    "fmt"
    "net/http"
    //"github.com/araddon/dateparse"
    "io/ioutil"
    "log"
    "math/rand"
    "os"
    "strconv"
    "strings"
    "time"

    yaml "gopkg.in/yaml.v2"

    _ "github.com/lib/pq"
)

const (
    version          = `2019-09-19`
    placeholdersHelp = `check.action values:
check = only report cases - intended for analysis
cancel = cancel query but preserve session
terminate = terminate whole session`
)

type data struct {
    pgURI        string
    pgDB         *sql.DB
    skipErrors   bool
    slackChannel string
    slackUser    string
    slackURL     string
}

type queryfile struct {
    PostgreSQLURI string `yaml:"uri"` // PostgreSQL URI
    Slack         struct {
        URL     string `yaml:"url,omitempty"`
        User    string `yaml:"user,omitempty"`
        Channel string `yaml:"channel,omitempty"`
    } `yaml:"slack,omitempty"`
    Check []struct {
        Name          string `yaml:"name"`
        RunTimeLimit  string `yaml:"runtime,omitempty"`         // interval in postgresql format like '1hour', '3minutes' etc.
        WaitEvent     string `yaml:"wait_event,omitempty"`      // as in pg_stat_activity - relation
        WaitEventType string `yaml:"wait_event_type,omitempty"` // as in pg_stat_activity - Lock
        State         string `yaml:"state"`                     // as in pg_stat_activity
        Query         string `yaml:"query,omitempty"`           // mask for query check
        Action        string `yaml:"action"`                    // what to do with query - check, cancel, terminate - default is terminate
    } `yaml:"check"`
}

type queryResult struct {
    processID            string
    processState         string
    processRunTime       string
    processWaitEventType string
    processWaitEvent     string
    processUseName       string
    processClientAddr    string
    processQuery         string
}

var (
    printHelp        = false
    showProgress     = false
    maximumRuns      = 5
    stepForMsg       = 10000
    runID            = ""
    processedLimit   = 50000
    printDebugMsg    = false
    debugLevel       = 0
    skipSlackMessage = false

    cancelProcessQueryMask    = `select pg_cancel_backend(${PID})`
    terminateProcessQueryMask = `select pg_terminate_backend(${PID})`
    queryRunTimeQueryMask     = ` and query_runtime > interval'${RUNTIMELIMIT}' `
    waitEventQueryMask        = ` and wait_event = '${WAITEVENT}' `
    waitEventTypeQueryMask    = ` and wait_event_type = '${WAITEVENTTYPE}' `
    queryStateQueryMask       = ` and state = '${QUERYSTATE}' `
    checkProcessesQueryMask   = `SELECT pid::text "processid", state, query_runtime::text as query_runtime, wait_event_type, wait_event, usename, client_addr, query
from public.view_pg_stat_activity where query not ilike '%vacuum%' and pid <> pg_backend_pid() ${QUERYRUNTIME} ${WAITEVENT} ${WAIREVENTTYPE} ${QUERYSTATE} order by query_runtime`
)

func printProgramVersion() {
    printMsg(os.Args[0], "version: ", version)
    return
}

func main() {
    runID = "[" + strconv.Itoa(rand.Intn(1000000000)) + "] "
    var d data

    var configFile string

    var err error
    var qf queryfile

    paramConfigfile := flag.String("configfile", "", "config file for the task")
    paramCheckOnly := flag.Bool("check_only", false, "only do check, do not terminate any query")

    paramHelp := flag.Bool("help", false, "print help")
    paramDebug := flag.Bool("debug", false, "print debug messages")

    paramProgress := flag.Bool("progress", false, "show progress during inserts into PostgreSQL")
    paramPrintVersion := flag.Bool("version", false, "print version of the code")

    paramDebugLevel := flag.Int("debug_level", debugLevel, "level of debug messages: 0 = default, common messages from run / 1 = show variables, queries etc. / 2 = deep debug, shows inserted data etc.")
    flag.Parse()

    configFile = *paramConfigfile
    printVersion := *paramPrintVersion
    doCheckOnly := *paramCheckOnly

    if printVersion == true {
        printProgramVersion()
        log.Fatalln()
    }

    printHelp = *paramHelp
    printDebugMsg = *paramDebug
    debugLevel = *paramDebugLevel
    showProgress = *paramProgress

    printProgramVersion()
    debugMsg(0, "config file: ", configFile)
    debugMsg(0, "printHelp: ", printHelp)
    debugMsg(0, "printDebugMsg: ", printDebugMsg)
    debugMsg(0, "debugLevel: ", debugLevel)
    debugMsg(0, "doCheckOnly: ", doCheckOnly)

    if printHelp == true || configFile == "" {
        printProgramVersion()
        if configFile == "" {
            printMsg("you have to specify config file")
        }
        flag.PrintDefaults()
        printMsg(placeholdersHelp)
        log.Fatalln()
    }

    if _, err := os.Stat(configFile); os.IsNotExist(err) {
        log.Fatalln("ERROR: Cannot find config file", configFile, "message:", err)
    }

    yamlFile, err := ioutil.ReadFile(configFile)
    if err != nil {
        log.Fatalln(runID, "ERROR: cannot read config file: ", err)
    }

    err = yaml.Unmarshal(yamlFile, &qf)
    if err != nil {
        log.Fatalln(runID, "ERROR: cannot unmarshal config file: ", err)
    }

    if qf.PostgreSQLURI == "" {
        log.Fatalln(runID, "ERROR: config file must contain PostgreSQL URI")
    }

    d.pgURI = qf.PostgreSQLURI
    checkValue("source postgresql URI", d.pgURI, true, printDebugMsg)

    d.slackURL = qf.Slack.URL
    d.slackUser = qf.Slack.User
    d.slackChannel = qf.Slack.Channel
    debugMsg(0, "d.slackURL: ", d.slackURL)
    debugMsg(0, "d.slackUser: ", d.slackUser)
    debugMsg(0, "d.slackChannel: ", d.slackChannel)

    debugMsg(0, "opening PG source connection...")
    d.pgDB, err = sql.Open("postgres", d.pgURI)
    if err != nil {
        log.Fatalln("ERROR: Cannot connect into postgresql db: ", err)
    }
    defer func() {
        if errClose := d.pgDB.Close(); err != nil {
            log.Println("closing source database:", errClose.Error())
        }
    }()
    if err = d.pgDB.Ping(); err != nil {
        log.Fatalln("ERROR: Cannot ping postgresql db: ", err)
    }

    osHostname, err := os.Hostname()
    if err != nil {
        log.Fatalln("ERROR: cannot read hostname: ", err)
    }

    for index, checkPart := range qf.Check {
        debugMsg(1, "check index: ", index)
        debugMsg(1, "checkPart.Name: ", checkPart.Name)
        debugMsg(1, "checkPart.RunTimeLimit: ", checkPart.RunTimeLimit)
        debugMsg(1, "checkPart.WaitEvent: ", checkPart.WaitEvent)
        debugMsg(1, "checkPart.WaitEventType: ", checkPart.WaitEventType)
        debugMsg(1, "checkPart.State: ", checkPart.State)
        debugMsg(1, "checkPart.Query: ", checkPart.Query)
        debugMsg(1, "checkPart.Action: ", checkPart.Action)

        if checkPart.State == "" {
            log.Fatalln("ERROR: check ", checkPart.Name, " does not contain state specification")
        }
        checkProcessesQuery := checkProcessesQueryMask
        queryRunTimeQuery := ""
        if checkPart.RunTimeLimit != "" {
            queryRunTimeQuery = strings.Replace(queryRunTimeQueryMask, "${RUNTIMELIMIT}", checkPart.RunTimeLimit, -1)
        }
        checkProcessesQuery = strings.Replace(checkProcessesQuery, "${QUERYRUNTIME}", queryRunTimeQuery, -1)
        waitEventQuery := ""
        if checkPart.WaitEvent != "" {
            waitEventQuery = strings.Replace(waitEventQueryMask, "${WAITEVENT}", checkPart.WaitEvent, -1)
        }
        checkProcessesQuery = strings.Replace(checkProcessesQuery, "${WAITEVENT}", waitEventQuery, -1)
        waitEventTypeQuery := ""
        if checkPart.WaitEventType != "" {
            waitEventTypeQuery = strings.Replace(waitEventTypeQueryMask, "${WAITEVENTTYPE}", checkPart.WaitEventType, -1)
        }
        checkProcessesQuery = strings.Replace(checkProcessesQuery, "${WAIREVENTTYPE}", waitEventTypeQuery, -1)
        queryStateQuery := ""
        if checkPart.State != "" {
            queryStateQuery = strings.Replace(queryStateQueryMask, "${QUERYSTATE}", checkPart.State, -1)
        }
        checkProcessesQuery = strings.Replace(checkProcessesQuery, "${QUERYSTATE}", queryStateQuery, -1)
        debugMsg(1, "checkProcessesQuery: ", checkProcessesQuery)

        rows, err := d.pgDB.Query(checkProcessesQuery)
        if err != nil {
            log.Fatalln("ERROR: could not run query for partitioning values:", err)
        }

        taskMsg := fmt.Sprint("[", osHostname, "] task: ", index, ": ", checkPart.Name, " (", checkPart.Action, ")")
        printMsg(taskMsg)
        var qr queryResult
        rowsFound := 0
        if rows != nil {
            for rows.Next() {
                if err = rows.Scan(&qr.processID, &qr.processState, &qr.processRunTime, &qr.processWaitEventType,
                    &qr.processWaitEvent, &qr.processUseName, &qr.processClientAddr, &qr.processQuery); err != nil {
                    log.Fatalln("ERROR: cannot query processes: ", err)
                }
                debugMsg(2, "query result: ", qr)
                processMsg := fmt.Sprint("pid:", qr.processID, ", query: ", qr.processQuery, ", runtime: ", qr.processRunTime)
                if doCheckOnly == false {
                    if checkPart.Action == "terminate" {
                        terminateProcessQuery := strings.Replace(terminateProcessQueryMask, "${PID}", qr.processID, -1)
                        outputMsg := taskMsg + " - terminating session: " + processMsg
                        debugMsg(0, "terminateProcessQuery: ", terminateProcessQuery)
                        printMsg(outputMsg)
                        runPgQuery(d.pgDB, terminateProcessQuery, "cancel query", true)
                        sendSlackMessage(outputMsg, d)
                    } else if checkPart.Action == "cancel" {
                        cancelProcessQuery := strings.Replace(cancelProcessQueryMask, "${PID}", qr.processID, -1)
                        outputMsg := taskMsg + " - canceling query: " + processMsg
                        debugMsg(0, "cancelProcessQuery: ", cancelProcessQuery)
                        printMsg(outputMsg)
                        runPgQuery(d.pgDB, cancelProcessQuery, "cancel query", true)
                        sendSlackMessage(outputMsg, d)
                    } else if checkPart.Action == "check" {
                        printMsg("Checking process: ", processMsg)
                    }
                } else {
                    printMsg("required check only - found process: ", processMsg)
                }
                rowsFound++
            }
        }
        printMsg("Rows processed: ", rowsFound)
    }

    printMsg("ALL DONE")

}

func runPgQuery(pgDB *sql.DB, query string, description string, exitOnError bool) {
    debugMsg(0, description, ": ", query)
    _, err := pgDB.Exec(query)
    if err != nil {
        if exitOnError == true {
            log.Fatalln("ERROR: Cannot run ", description, ": ", err, " Query: ", query)
        } else {
            printMsg("WARNING: Cannot run ", description, ": ", err, " Query: ", query)
        }
    }
}

func runPgQueryCommit(pgDB *sql.DB, query string, description string, exitOnError bool) {
    debugMsg(0, "runPgQueryCommit: ", description, ": ", query)
    pgTrans, err := pgDB.Begin() // start transaction[3] pgquerycommit
    if err != nil {
        log.Fatal("runPgQueryCommit - ERROR: cannot open transaction on select db:", err)
    }
    stmt, err := pgTrans.Prepare(query)
    if err != nil {
        log.Fatalln("runPgQueryCommit - ERROR: cannot prepare statement (", query, "): ", err)
    }
    result, err := stmt.Exec()
    if err != nil {
        if exitOnError == true {
            log.Fatalln("ERROR: Cannot run ", description, ": ", err, " Query: ", query)
        } else {
            printMsg("WARNING: Cannot run ", description, ": ", err, " Query: ", query)
        }
    }
    debugMsg(1, "runPgQueryCommit: ", description, " output: ", result)
    err = pgTrans.Commit() // end transaction[3] pgquerycommit
    if err != nil {
        log.Fatalln("ERROR: cannot commit pg transaction:", err)
    }
}

func curTime() string {
    return time.Now().UTC().Format(time.RFC3339) + ":"
}

func debugMsg(level int, t ...interface{}) {
    if printDebugMsg == true && level <= debugLevel {
        printMsg(t...)
    }
}

func printMsg(t ...interface{}) {
    fmt.Println(curTime(), fmt.Sprint(t...))
}

func checkValue(name string, value string, required bool, print bool) {
    if value == "" && required == true {
        log.Fatalln("ERROR: variable ", name, " cannot be empty!")
    }
    if print == true {
        debugMsg(0, name, ": ", value)
    }
}

func fullTableName(schema string, table string) (fullname string) {
    fullname = `"` + schema + `"."` + table + `"`
    return
}

func sendSlackMessage(msg string, d data) {
    slackMessage := strings.NewReader(fmt.Sprintf("{\"channel\": \"%s\", \"username\": \"%s\", \"text\": \"%s\" }", d.slackChannel, d.slackUser, msg))
    debugMsg(0, "sendSlackMessage: d.slackChannel - ", d.slackChannel)
    debugMsg(0, "sendSlackMessage: d.slackUser - ", d.slackUser)
    debugMsg(0, "sendSlackMessage: d.slackURL - ", d.slackURL)
    debugMsg(0, "sendSlackMessage: slackMessage - ", slackMessage)
    if d.slackURL != "" {
        if skipSlackMessage == false {
            req, err := http.NewRequest("POST", d.slackURL, slackMessage)
            if err != nil {
                printMsg("ERROR: Failed to create a request for slack message:", err, " message: ", msg)
                return
            }
            req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

            resp, err := http.DefaultClient.Do(req)
            if err != nil {
                printMsg("ERROR: Failed to send slack message:", err, " message: ", msg)
                return
            }
            defer resp.Body.Close()
            printMsg("Slack message sent: ", slackMessage, " - response: ", resp)
        } else {
            printMsg("skip Slack mode: ", slackMessage)
        }
    } else {
        printMsg("Slack URL is not defined: ", slackMessage)
    }
}

/*
How config file looks like (yaml format):

check:

name: query active for more then 1 hour
runtime: “1 hour”
state: active
action: check
name: query active for more then 6 hours
runtime: “12 hours”
state: active
action: terminate
name: query waiting for lock on relation more then 10 minutes
runtime: “10 minutes”
state: active
wait_event: relation
wait_event_type: Lock
action: terminate
name: idle in transaction for more then 1 hour
runtime: “1 hour”
state: “idle in transaction”
action: check
name: idle in transaction for more then 6 hour
runtime: “6 hours”
state: “idle in transaction”
action: terminate
*/
