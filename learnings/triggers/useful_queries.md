# Triggers – some useful queries
show parent tables with trigger names:
```
select inhparent, inhparent::regclass, count(*) as _count, (select string_agg(tgname,',') from pg_trigger t where t.tgrelid=i.inhparent ) as triggers from pg_inherits i group by 1 order by 1;
```
show tables with user created triggers  + procedure name + procedure source code:
```
select nst.nspname as table_schema, ct.relname as table_name,
t.tgname as trigger_name, p.proname as procedure_name, p.prosrc as procedure_source
from pg_trigger t
left join pg_proc p on t.tgfoid=p.oid
left join pg_class ct on t.tgrelid = ct.oid
left join pg_namespace nst on ct.relnamespace=nst.oid
where t.tgisinternal is false
```
