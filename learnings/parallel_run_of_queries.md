# Parallel run of queries / functions / tasks using dblink

Up until PostgreSQL 11 there was one problem which limited scalability.
One process / session / connection could use only one CPU / core.

Therefore if you wanted to run several queries / tasks / functions in parallel you have to use dblink functions to open more parallel connections into database.

Of course you have to keep in mind these rules:

* every dblink connection is independent on others and also will commit independently
* until connection commits changes made by this connection are not visible to others even to your main process
* if you made some changes in your main process they also will NOT be visible for dblink connections because these changes will be committed only at the end of main procedure
* therefore if you for example need to prepare data or tables for tasks you want to run later in parallel using dblink you have to make these changes also using dblink connection

Basic schema to run more queries in parallel:

* open as many connections as you need using `perform dblink_connect( ‘…connection_name…’, ‘…connection_string…’);`
* every connection MUST have a unique name
* store these connection names in array or temporary table
* send query into every connection using `dblink_send_query(‘…connection_name…’, ‘…query_text_or_function_call_etc…’)`
* command returns status but does not wait for query results

test in cycle if query is done:

1. variant:

* using “dblink_get_result” which waits for result – so command will wait until first connection is done and only then it will skip in cycle to second connection etc.
* if query ends with error it will be thrown as exception into your main process – so you have to catch it to prevent your main procedure to crash

2. variant:

* using “dblink_is_busy” check in cycle every connection
* result = “0” means that remote query ended – then use “dblink_error_message” to check if query ended OK or with error
* if result is NULL or ‘OK’ then use “dblink_get_result” to get eventually returned function result etc.
* if query ends with error then error message is in result of “dblink_error_message”

at the end disconnect all sessions using “dblink_disconnect”

There are some limitations:

* Into one connection you can send query only once.
  * You cannot send another query into connection after your first query ends.
  * You have to close connection and open again.
* You have to be careful how many parallel connection you open.
  * Every new connection will use one more CPU / core and some part of memory.
  * If you open too many connections you can easily kill performance.
  * Or even cause some other PG connection to crash – which will cause recovery mode on database and all your connections will be killed. All depends on your HW configuration, OS etc…

So that’s it! Go parallel end enjoy it!
