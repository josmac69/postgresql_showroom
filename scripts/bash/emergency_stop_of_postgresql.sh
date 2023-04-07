#!/bin/bash

# Bash script for emergency stop of PostgreSQL
# PostgreSQL has one serious weakness – it crashes when some of filesystems it uses if full.
# Plus PostgreSQL is unable to check if such problem is comming. It simply crashes with error like this:
# PANIC:  could not write to file "pg_xlog/xlogtemp.1752": No space left on device
# For example MySQL is able to survive such a situation –
# it is able to block sessions which cannot write to disk due to not enough free disk space.
# In case of PostgreSQL we have so far (PG 10) only 2 possibilities:
# either let PostgreSQL crash (and risk data damage – which is very likely to happen)
# or implement some solution which will check remaining empty space on disks and force emergency stop of PostgreSQL
# if it reaches some limit (otherwise PostgreSQL will crash anyway)
# Here is one simple solution which could inspire you – bash script which is able to check remaining empty space
# on all filesystems PostgreSQL uses (main directory, pg_xlog/ pg_wal, tablspaces) –
# all of them are checked because some installation can have very complicated architecture.
# Directories can be on different filesystems accessed through soft links.
# Script has two different levels of checks – warning and stop.
# If warning limit is reached then e-mail warning is send.
# If stop limit is reached then PostgreSQL is stopped using pg_ctl command.
# It requires to set ENV variables in external file which is sourced at the beginning of the script.
# It sends e-mail too in case of stopping PostgreSQL.
# It uses gmail account and it is tailored for our enviromnent but it can be modified in simple way.

dryrun=${1:-0}
if [ "$dryrun" != "0" ]; then
  dryrun=1
fi

function echo_log {
  echo "$(date +"%Y-%m-%d %H:%M:%S.%N"): $1"
}

if [ "$EUID" -ne 0 ]; then
  echo_log "Please run this script as root"
  exit 1
fi

homedir=$( dirname "${BASH_SOURCE[0]}")
cd $homedir
. ./.pg_env

# content of .pg_env
# export PGCTL_CMD=... - full path to pg_ctl file - like /usr/lib/postgresql/9.6/bin/pg_ctl
# export PG_PORT=... - pg port - like 5432
# export PG_CHECK_WARNING_LIMIT=... - space limit for e-mail warning - size in bytes - like 10737418240 (=10GB)
# export PG_CHECK_STOP_LIMIT=... - space limit in bytes for issuing emergency stop of PG - like 1073741824 (=1GB)
# export GMAIL_ACCOUNT=notifications@yourdomain.com
# export GMAIL_PASSWORD=...
# export TARGET_EMAILS=... list of emails, delimited with ","

[ -z "$PGCTL_CMD" ] && echo_log "$(basename $0): ERROR: variable PGCTL_CMD empty or undefined" && exit 1
[ -z "$PG_PORT" ] && echo_log "$(basename $0): ERROR: variable PG_PORT empty or undefined" && exit 1
[ -z "$PG_CHECK_WARNING_LIMIT" ] && echo_log "$(basename $0): ERROR: variable PG_CHECK_WARNING_LIMIT empty or undefined" && exit 1
[ -z "$PG_CHECK_STOP_LIMIT" ] && echo_log "$(basename $0): ERROR: variable PG_CHECK_STOP_LIMIT empty or undefined" && exit 1
[ -z "$GMAIL_ACCOUNT" ] && echo_log "$(basename $0): ERROR: variable GMAIL_ACCOUNT empty or undefined" && exit 1
[ -z "$GMAIL_PASSWORD" ] && echo_log "$(basename $0): ERROR: variable GMAIL_PASSWORD empty or undefined" && exit 1
[ -z "$TARGET_EMAILS" ] && echo_log "$(basename $0): ERROR: variable TARGET_EMAILS empty or undefined" && exit 1

let warninglimitkb=${PG_CHECK_WARNING_LIMIT}/1024
let stoplimitkb=${PG_CHECK_STOP_LIMIT}/1024
instance=$(hostname)

if [[ ${PG_CHECK_WARNING_LIMIT} -le ${PG_CHECK_STOP_LIMIT} ]]; then
  echo_log "ERROR: warning limit must be bigger then stop limit"
  exit 1
fi

pgctlpath=$(command -v ${PGCTL_CMD})
if [ -z "${pgctlpath}" ]; then
  echo_log "ERROR: cannot find pg_ctl utility"
  exit 1
fi

function send_email {
  msubject="$1"
  mtext="$2"
  sendemail -m "${mtext}" -f "${GMAIL_ACCOUNT}" -u "${msubject}" -t ${TARGET_EMAILS} -s smtp.gmail.com:587 -xu "${GMAIL_ACCOUNT}" -xp ${GMAIL_PASSWORD} -o tls=yes
}

function get_free_space {
  dirsrc="$1"
  dirfull=$(readlink -m ${dirsrc})
  if [ -d ${dirfull} ]; then
    dirfree=$(df -k --output=avail ${dirfull}|tail -n1)
    echo_log "checking: ${dirfull} - free space: ${dirfree} KB, warning limit: ${warninglimitkb} KB, stop limit: ${stoplimitkb} KB"
    mail_text="Emergency check of PostgreSQL\n\nDate: $(date +"%Y-%m-%d %H:%M:%S.%N")\nInstance: ${instance}\nDirectory: ${dirfull}\nWarning limit: ${warninglimitkb} KB\nStop limit: ${stoplimitkb} KB\nAvailable space: ${dirfree} KB"

    ## stop limit
    if [[ ${dirfree} -lt ${stoplimitkb} ]]; then
      echo_log "NOT enough space on filesystem - issuing emergency stop of postgresql!"
      if [[ "${pgctlpath}" != "" && "${pgdatadirsrc}" != "" ]]; then
        cmd="su -c \"${pgctlpath} -D ${pgdatadirsrc} stop -m fast\" postgres"
        echo_log "$cmd"
        if [[ $dryrun -eq 0 ]]; then
          eval "$cmd"
          send_email "Emergency stop of PostgreSQL on ${instance}" "${mail_text}\n\nPostgreSQL was stopped!"
          exit 1
        else
          echo_log "dry run - skipping emergency stop"
        fi
      fi
    fi

    ## warning limit
    if [[ ${dirfree} -le ${warninglimitkb} ]]; then
      echo_log "space on filesystem reached warning limit!"
      echo_log "sending warning e-mail..."
      send_email "Warning - not enough space on ${instance}" "${mail_text}\n\nThis is warning e-mail"
    fi

  else
    echo_log "directory does not exist: ${dirfull}"
  fi
}

echo_log "===== PostgreSQL emergency check ===="
echo_log "pg_ctl utility: ${pgctlpath}"

#### pg data dir
pgdatadirsrc=$(su -c "psql -p ${PG_PORT} -t -c \"select setting from pg_settings where name = 'data_directory';\" 2>/dev/null|tr -d ' '" postgres)
if [ -z ${pgdatadirsrc} ]; then
  echo_log "ERROR: cannot query postgresql data_directory !"
  exit 1
fi
get_free_space "${pgdatadirsrc}"

#### pg_xlog dir
pgxlogdirsrc="${pgdatadirsrc}/pg_xlog"
get_free_space "${pgxlogdirsrc}"

#### pg_wal dir
pgwaldirsrc="${pgdatadirsrc}/pg_wal"
get_free_space "${pgwaldirsrc}"

#### tablespaces
for tblspc in $(su -c "psql -p ${PG_PORT} -t -c \"select loc from (select nullif(pg_tablespace_location(oid),'') as loc from pg_tablespace) src where loc is not null;\"" postgres ); do
  get_free_space "${tblspc}"
done

echo_log "Check DONE"
