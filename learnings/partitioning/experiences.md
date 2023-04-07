# Experiencies with table partitioning done by inheritance in PostgreSQL 9.x

This text is based on my experience with PG 8.4 and 9.3.

Here are some useful selects:

* Show row count pro every child table:
```
select c.relname, count(*)
from schemaname.parent_table m
join pg_class c
on m.tableoid=c.oid
group by c.relname
```
* or this “nerd-stuff” query – which gives the same result only using CAST:
```
select tableoid::regclass, count(*)
from schemaname.parent_table m
group by tableoid
order by 1
```
* Show all parent-child tables in database:
```
select p.relname as parent_table, ch.relname as child_table, i.inhseqno
from pg_inherits i
join pg_class p
on i.inhparent = p.oid
join pg_class ch
on i.inhrelid = ch.oid
order by 1, 2
```
#### And here some experiences with table inheritance / partitioning in PostgreSQL:

* Problem with locks when using pg_bulkload to load into child tables:If you select data using query into parent table then all child tables are locked with “access shared lock” which can cause problems with pg_bulkload loading data into some child table.
* Because pg_bulkload uses “access exclusive lock” for table because it does also reindexing.
* So typical problem in such a case is that pg_bulkload waits for lock on child table until running selects are done.
* If there are some new queries launched after pg_bulkload requests exclusive lock they also have to wait. And they can continue only after pg_bulkload finishes its job and releases all locks.
* Only help in such a case is to use COPY command. It is maybe a little slower but does not need exclusive lock on the whole table.
* So in reality using COPY can give you better responses than “quicker” pg_bulkload
