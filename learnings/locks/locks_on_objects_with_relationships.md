# Locks on objects with relationships

If you want to check for specific object – specify it in WHERE clause.

Explanations for the content of the result:

* connection which locks is selected at the top, connections which waits for lock a bellow
* every connection has also its unique “virtualtransaction”
  * for every connection (virtualtransaction) there can be more rows in the list:
    — relation – contains object which is locked or lock is awaited
    — tuple – is present if process locks specific row (see bellow)
    — transactionid – indicates opening of transaction, contains transaction id of the lock which is held or which blocks locking
    — virtualxid – indicates creating of virtual transaction id, contains this id in column “virtualxid”
    — object –
    — userlock – indicates lock made by LOCK command by user
    — advisory – indicates advisory lock made by user
    — extend –
    — page –

Locking and waiting processes:

* locking process: query_lock_status=’locks’ + lock_granted=’held’ + transactionid NOT NULL –> this connection has locked object listed in row with “locktype” = ‘relation’ with the same “virtualtransaction” as this row
* waiting process: query_lock_status=’waits’ + lock_granted=’awaited’ + transactionid NOT NULL (and the same as above) –> this connection is waiting for lock and is being blocked by connection specified above (now value in “transactionid” indicates blocking transactionid)
* but also connection with query_lock_statut=’waits’ can have rows with lock_granted=’held’ + transactionid NOT NULL (some other) – then this lock which will be created after blocking lock will be released
* there can be more levels of holding and awaiting, if there is multiple transaction competing for the same object and the same rows

Lock on specific row:

* if process locks or awaits lock for only specific row then this is indicated by values in columns “page” (ord.num. of page with row) and “tuple” (ord.num of row/tuple in page) – in row with “locktype” = ‘tuple’.
* rows with the same values in columns “page” and “tuple” compete for the same record, locking connection is the one with “lock_granted” = ‘held’, others await for lock.
* if locked object is index, then index access method is indicated in row “index_am”

Other notices:

* view pg_locks shows locks over entire server, but view pg_class which provides object name contains only objects from current database, therefore rows for locks on other databases will not show object names, only rows for current database will have them

Version for PostgreSQL 8.4-9.2:

```
select     l.pid as connection_id,
a.usename as user_name,
a.datname as "database",
case when a.waiting is false then 'locks'
else 'waits' end as query_lock_status,
case when l.granted is true then 'held'
else 'awaited' end as lock_granted,
l.transactionid,
l.virtualxid,
l.virtualtransaction,
l.locktype,
l.mode as lock_mode,
ns.nspname as "schema",
c.relname as "locked_object",
case relkind
when 'r' then 'table'
when 'i' then 'index'
when 'S' then 'sequence'
when 'v' then 'view'
when 'c' then 'composite type'
when 't' then 'TOAST table'
else relkind||'?'
end as "object_type",
a.current_query,
a.xact_start as transaction_start,
a.query_start,
a.backend_start as connection_start,
a.client_addr,
a.client_port,
l.page,
l.tuple,
l.classid,
l.objid,
l.objsubid,
case when coalesce(c.relam,0)!=0 then
(select amname from pg_am am where c.relam = am.oid)
else null end as "index_am"
from     pg_locks l
left join pg_database d
on     l.database = d.oid
left join pg_class c
on     l.relation = c.oid
left join pg_namespace ns
on    c.relnamespace = ns.oid
left join pg_stat_activity a
on     l.pid = a.procpid
where     l.pid <> pg_backend_pid()
--specifies object we are testing, otherwise comment this next row away
--and l.pid in (select lx.pid from pg_locks lx join pg_class cx on lx.relation = cx.oid
--join pg_namespace nsx on cx.relnamespace = nsx.oid
--where nsx.nspname = '...your_schema....' and cx.relname = '...your_table....' )
order by a.waiting,
a.xact_start,
l.locktype,
a.current_query

```

Version for PostgreSQL 9.3-9.5:

```
select     l.pid as connection_id,
a.usename as user_name,
a.datname as "database",
case when a.waiting is false then 'locks'
else 'waits' end as query_lock_status,
case when l.granted is true then 'held'
else 'awaited' end as lock_granted,
l.transactionid,
l.virtualxid,
l.virtualtransaction,
l.locktype,
l.mode as lock_mode,
ns.nspname as "schema",
c.relname as "locked_object",
case relkind
when 'r' then 'table'
when 'i' then 'index'
when 'S' then 'sequence'
when 'v' then 'view'
when 'c' then 'composite type'
when 't' then 'TOAST table'
else relkind||'?'
end as "object_type",
a.application_name,
a.query,
a.xact_start as transaction_start,
a.query_start,
a.backend_start as connection_start,
a.client_addr,
a.client_port,
l.page,
l.tuple,
l.classid,
l.objid,
l.objsubid,
case when coalesce(c.relam,0)!=0 then
(select amname from pg_am am where c.relam = am.oid)
else null end as "index_am"
from     pg_locks l
left join pg_database d
on     l.database = d.oid
left join pg_class c
on     l.relation = c.oid
left join pg_namespace ns
on    c.relnamespace = ns.oid
left join pg_stat_activity a
on     l.pid = a.pid
where     l.pid <> pg_backend_pid()
--specifies object we are testing, otherwise comment this next row away
--and l.pid in (select lx.pid from pg_locks lx join pg_class cx on lx.relation = cx.oid
--join pg_namespace nsx on cx.relnamespace = nsx.oid
--where nsx.nspname = '...your_schema...' and cx.relname = '...your_table...' )
order by a.waiting desc,
a.xact_start,
l.locktype,
a.query,
"database"

```

Version for PostgreSQL 9.6+:

```
select     l.pid as connection_id,
a.usename as user_name,
a.datname as "database",
case when a.wait_event is false then 'locks'
else 'waits' end as query_lock_status,
case when l.granted is true then 'held'
else 'awaited' end as lock_granted,
a.wait_event_type,
a.wait_event,
l.transactionid,
l.virtualxid,
l.virtualtransaction,
l.locktype,
l.mode as lock_mode,
ns.nspname as "schema",
c.relname as "locked_object",
case relkind
when 'r' then 'table'
when 'i' then 'index'
when 'S' then 'sequence'
when 'v' then 'view'
when 'c' then 'composite type'
when 't' then 'TOAST table'
else relkind||'?'
end as "object_type",
a.application_name,
a.query,
a.xact_start as transaction_start,
a.query_start,
a.backend_start as connection_start,
a.client_addr,
a.client_port,
l.page,
l.tuple,
l.classid,
l.objid,
l.objsubid,
case when coalesce(c.relam,0)!=0 then
(select amname from pg_am am where c.relam = am.oid)
else null end as "index_am"
from     pg_locks l
left join pg_database d
on     l.database = d.oid
left join pg_class c
on     l.relation = c.oid
left join pg_namespace ns
on    c.relnamespace = ns.oid
left join pg_stat_activity a
on     l.pid = a.pid
where     l.pid <> pg_backend_pid()
--specifies object we are testing, otherwise comment this next row away
--and l.pid in (select lx.pid from pg_locks lx join pg_class cx on lx.relation = cx.oid
--join pg_namespace nsx on cx.relnamespace = nsx.oid
--where nsx.nspname = '...your_schema...' and cx.relname = '...your_table...' )
order by a.waiting desc,
a.xact_start,
l.locktype,
a.query,
"database"
```
