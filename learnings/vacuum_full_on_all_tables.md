# VACUUM FULL on all tables
Usual vacuum process cannot reclaim back free space from tables into OS. It just cleans deleted records and makes space in data pages but does not shrink data files. Which is OK if you keep using those tables for further updates and inserts. But if you have some partitioned tables partitioned by time then probably you will never again write anything into old partitions. Only VACUUM FULL can shrink tables but this command is not that easy to run. If you run it on whole database it often happens that VACUUM process will collide with autovacuum background workers and will went into waiting state and may never start again. At least this happened to me. Command VACUUM also cannot be launched from PostgreSQL function because it cannot run inside BEGIN – END block.

So here is small script to perform external “VACUUM FULL” on every table separately. Script deliberately skips parent tables because if you issue VACUUM FULL on parent table it obviously starts to process all children. Which can be suicide if you have not enough disk space and big data in those child tables. Therefore it process every child table separately.

```
#!/bin/bash

DATABASENAME=$1
DATABASEUSER=$2

if [ -z $DATABASENAME ] || [ -z $DATABASEUSER ]; then
  echo "USAGE: ./$(basename $0) db_name db_user"
  exit 1
fi

for tablename in $(psql -U upcload -d $DATABASENAME -t -c "select table_schema||'.'||table_name as _table from information_schema.tables t where not exists( select isparent from ( select ns.nspname||'.'||relname as isparent from pg_class c join pg_namespace ns on ns.oid=c.relnamespace where c.oid in ( select i.inhparent from pg_inherits i group by inhparent having count(*)>0) ) a where a.isparent=t.table_schema||'.'||t.table_name ) order by _table"); do
  echo $tablename
  psql -U $DATABASEUSER -d $DATABASENAME -c "vacuum full analyze verbose ${tablename};"
done
```
