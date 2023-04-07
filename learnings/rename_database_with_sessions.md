# How to rename database with active sessions
Useful when you need to for example switch databases – you must do it from psql when connected to other database (db postgres is the best choice in this case):

* restrict further connections into this database: `ALTER DATABASE your_old_database CONNECTION LIMIT 0;`
* close existing sessions with:
```
select pg_terminate_backend(procpid) from pg_stat_activity where datname = ‘your_old_database’ and procpid <> pg_backend_pid();
```
* rename old to different name
* rename new to proper name
* allow connections on old database:
```
ALTER DATABASE your_old_renamed_database CONNECTION LIMIT -1;
```
