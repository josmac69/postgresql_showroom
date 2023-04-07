# Logical replication - check published and subscribed tables for PRIMARY KEYs
* This problem can happen when you published some tables but later when you perform UPDATE operation you get error like this:
```
ERROR: cannot update table “xxxxxx” because it does not have a replica identity and publishes updates
HINT: To enable updating the table, set REPLICA IDENTITY using ALTER TABLE.
```
* This error message means that PRIMARY KEY is missing. You can use this select to check if published tables have PRIMARY KEYs:
```
with primarykey as (
select kcu.table_schema,
       kcu.table_name,
       tco.constraint_name,
       kcu.ordinal_position as position,
       kcu.column_name as key_column
from information_schema.table_constraints tco
join information_schema.key_column_usage kcu
     on kcu.constraint_name = tco.constraint_name
     and kcu.constraint_schema = tco.constraint_schema
     and kcu.constraint_name = tco.constraint_name
where tco.constraint_type = 'PRIMARY KEY'
order by kcu.table_schema,
         kcu.table_name,
         position),
published as (select * from pg_publication_tables)
select *
from published p
left join primarykey k on k.table_schema=p.schemaname and k.table_name=p.tablename;
```
* To add PRIMARY KEY to specific table use (if ID is not proper name replace it with your “identity” column):
```
ALTER TABLE xxx.xxx ADD PRIMARY KEY (ID);
```
* Check of subscribed tables:
```
with primarykey as (
select kcu.table_schema,
       kcu.table_name,
       tco.constraint_name,
       kcu.ordinal_position as position,
       kcu.column_name as key_column
from information_schema.table_constraints tco
join information_schema.key_column_usage kcu
     on kcu.constraint_name = tco.constraint_name
     and kcu.constraint_schema = tco.constraint_schema
     and kcu.constraint_name = tco.constraint_name
where tco.constraint_type = 'PRIMARY KEY'
order by kcu.table_schema,
         kcu.table_name,
         position),
subscribed as (select srrelid::regclass::text as object from pg_subscription_rel)
select *
from subscribed s
left join primarykey k on k.table_schema||'.'||k.table_name=s.object;
```
