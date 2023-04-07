# PostgreSQL: No space left on device
* Error “no space left on device” is probably the biggest nightmare of every PostgreSQL admin.
* Below you can see how it looks like in pg main log.
* If this happens it usually means your database is screwed in some way because pg_xlog (pg_wal in version 10+) is directory with WAL logs.
* So if postgresql was not able to write WAL log then some changes are definitely lost.

```
yyyy-mm-dd HH:MM:02 UTC [935-177] PANIC:  could not write to file "pg_xlog/xlogtemp.935": No space left on device
yyyy-mm-dd HH:MM:02 UTC [935-178] CONTEXT:  writing block 86389 of relation base/16391/17666
yyyy-mm-dd HH:MM:03 UTC [690-2] LOG:  checkpointer process (PID 935) was terminated by signal 6: Aborted
yyyy-mm-dd HH:MM:03 UTC [690-3] LOG:  terminating any other active server processes
yyyy-mm-dd HH:MM:03 UTC [2812-3] username@databasename WARNING:  terminating connection because of crash of another server process
yyyy-mm-dd HH:MM:03 UTC [2812-4] username@databasename DETAIL:  The postmaster has commanded this server process to roll back the current transaction and exit, because another server process exited abnormally and possibly corrupted shared memory.
yyyy-mm-dd HH:MM:03 UTC [2812-5] username@databasename HINT:  In a moment you should be able to reconnect to the database and repeat your command.
yyyy-mm-dd HH:MM:03 UTC [2812-6] username@databasename CONTEXT:  COPY metrics_201701, line 9214101
yyyy-mm-dd HH:MM:03 UTC [938-2] WARNING:  terminating connection because of crash of another server process
yyyy-mm-dd HH:MM:03 UTC [938-3] DETAIL:  The postmaster has commanded this server process to roll back the current transaction and exit, because another server process exited abnormally and possibly corrupted shared memory.
yyyy-mm-dd HH:MM:03 UTC [938-4] HINT:  In a moment you should be able to reconnect to the database and repeat your command.
yyyy-mm-dd HH:MM:04 UTC [2838-3] username@databasename WARNING:  terminating connection because of crash of another server process
yyyy-mm-dd HH:MM:04 UTC [2838-4] username@databasename DETAIL:  The postmaster has commanded this server process to roll back the current transaction and exit, because another server process exited abnormally and possibly corrupted shared memory.
yyyy-mm-dd HH:MM:04 UTC [2838-5] username@databasename HINT:  In a moment you should be able to reconnect to the database and repeat your command.
yyyy-mm-dd HH:MM:04 UTC [2838-6] username@databasename CONTEXT:  COPY purchases_201701, line 1980505
yyyy-mm-dd HH:MM:05 UTC [690-4] LOG:  all server processes terminated; reinitializing
yyyy-mm-dd HH:MM:06 UTC [4099-1] LOG:  database system was interrupted; last known up at 2017-04-24 20:12:58 UTC
yyyy-mm-dd HH:MM:09 UTC [4099-2] LOG:  database system was not properly shut down; automatic recovery in progress
yyyy-mm-dd HH:MM:10 UTC [4099-3] LOG:  redo starts at D/BB2ACA18
yyyy-mm-dd HH:MM:12 UTC [4099-4] LOG:  redo done at D/D3FFE9F8
yyyy-mm-dd HH:MM:52 UTC [4099-5] FATAL:  could not write to file "pg_xlog/xlogtemp.4099": No space left on device
yyyy-mm-dd HH:MM:52 UTC [690-5] LOG:  startup process (PID 4099) exited with exit code 1
yyyy-mm-dd HH:MM:52 UTC [690-6] LOG:  aborting startup due to startup process failure
yyyy-mm-dd HH:MM:52 UTC [690-7] LOG:  database system is shut down
```

What to do in such case:

* First – before doing anything else backup content of your PostgreSQL main directory (directory containing pg_xlog / pg_wal subdirectory). If you have data in main/base directory and not enough space to backup it too just skip this directory.
* Try to find some files you can move from your disk with PG main directory to somewhere else to make some space for PostgreSQL to start. During startup it need to create / open several files so you would need about 100 MB of free space.
* By doing it NEVER touch any “pg_*” directory in PG main folder !!!
 * pg_xlog – contains Write Ahead Logs (WAL = transaction logs)
 * pg_clog – contains the commit log files – they describe status of a transaction. These logs are maybe even more important then WAL logs. Without it PG will never start !!!

If you cannot empty any space on current filesystem but you have other disks / filesystems available you can always move “base” subdirectory into another disk and create symbolic link to the new location replacing “base” directory in PG main directory. You must do it under postgres user !!!