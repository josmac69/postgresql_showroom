# Error “write failed” during SELECT command – on Linux machine

If you see error “write failed” during query run on Linux machine then it most probably means this:

* PostgreSQL is making query which demands big sorting, hashing etc.
* But there is not enough free memory so database has to write temporary files on disk
* But filesystem with temporary tablespace has not enough space

You need to check:

* check available memory on Linux machine using command: “free”
  * if column “free” (total/ used/ free) in output shows smaller amount then 1 GB then database almost certainly swaps temporary files on disk by bigger queries
  * if amount of free memory is bigger – like several GB then you need to estimate amount of data which database reads during query and compare it with free memory to see if it can fit into memory or not
  * of course command “free” show immediate status – if you are checking this error based on error log/ customer complains etc. you need to know more what is running as cron etc. and if necessary then to monitor free memory during a day
* check settings in database: “select * from pg_settings where name = ‘temp_tablespaces'”
* if column “setting” is empty then it means that database is using default
* default data_directory you can find: “select * from pg_settings where name = ‘data_directory’ “
* column “setting” shows directory name
* check on system using “df-h” how many free space is on filesystem when “data_directory” is placed
  * to evaluate result use the same rules as for memory

And now what to do to prevent this error:

1. If memory is an issue – add or request more memory for the machine – if possible
2. If disks are almost full – you must add or request more disks as highest priority otherwise you can see crash of the database in very near future. And crash of PostgreSQL is the real disaster – database usually cannot recover from it.
3. if only “data_directory” filesystem is small but tablespaces have enough space then set “temp_tablespaces” in postgresql.conf to list of tablespaces with enough space. PostgreSQL will then create temp files in them. (see documentation: “Temporary files (for operations such as sorting more data than can fit in memory) are created within PGDATA/base/pgsql_tmp, or within a pgsql_tmp subdirectory of a tablespace directory if a tablespace other than pg_default is specified for them. The name of a temporary file has the form pgsql_tmpPPP.NNN, where PPP is the PID of the owning backend and NNN distinguishes different temporary files of that backend.” – [http://www.postgresql.org/docs/9.3/static/storage-file-layout.html](https://web.archive.org/web/20201128131257/http://www.postgresql.org/docs/9.3/static/storage-file-layout.html))
