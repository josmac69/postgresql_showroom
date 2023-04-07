# PostgreSQL 10 – highlights

1. View “pg_stat_activity” contains new useful or updated existing columns which can help us to better track what is going on in the database:
   * wait_event_type – has now interesting values “Activity”, “Extension”, “Client”, “IPC”, “Timeout”, “IO”
   * “wait_event” – name of activity for new event types
   * “backend_type” – new column
2. View “pg_stat_replication” is heavily updated so you can see even lags.
3. New extended additional statistics for columns – new commands “CREATE STATISTICS” and “ALTER STATISTICS” + catalog in “pg_statistic_ext”
