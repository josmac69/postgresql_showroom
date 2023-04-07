# How to check blocked queries
* Lately I had to several cases with the same reason – hanging selects blocking changes in data. All cases on PostgreSQL 11. It almost looks like PG 11 does not recognize that client connection ended and is not listening anymore – all hanging processes had wait_event_type = “Client” and wait_event = “ClientWrite”. Database did not end database process even when all client processes already died out.
* Investigation is quite simple and “healing” too – just kill ( select pg_terminate_backend(xxxxx); ) all those hanging processes with mentioned wait_event* values.

Here are some useful queries for check:
```
select pid, usename, application_name, client_addr, state, wait_event, wait_event_type, query from pg_stat_activity psa where state = 'active'
```
locks on database:
```
select locktype, db.datname, ns.nspname, c.relname, virtualtransaction, pid, mode, granted from pg_locks l join pg_database db on l.database=db.oid join pg_class c on l.relation=c.oid join pg_namespace ns on c.relnamespace=ns.oid where nspname not in ('pg_catalog') and c.relname ilike '%'||'$searchqueryfor'||'%'
```
blocked queries:
```
select pid, usename, pg_blocking_pids(pid) as blocked_by, query as blocked_query from pg_stat_activity where cardinality(pg_blocking_pids(pid)) > 0
```
