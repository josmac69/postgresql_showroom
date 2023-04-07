/*
How to get information about partitions for new native partitioning in PostgreSQL
Lately I was facing problem of implementing some checks into our golang etl programs
which manipulate with partitions created using new native partitioning (PG 10 or higher).
Tables/views in the pg_catalog seems to not contain all information.
Only psql “\d” command seems to give all answers.
But to call psql with \d command inside golang program and process output is not exactly what I would like to do.

So putting it simply – answer can be found in psql source code
on github – https://github.com/postgres/postgres/blob/master/src/bin/psql/describe.c#L2107

This part prepares output for specific partition and here we can finally see pg_catalog functions used for retrieving information:

pg_catalog.pg_get_expr
pg_catalog.pg_get_partition_constraintdef
Code uses this query:

SELECT inhparent::pg_catalog.regclass, pg_catalog.pg_get_expr(c.relpartbound, c.oid)
 , pg_catalog.pg_get_partition_constraintdef(c.oid)
 FROM pg_catalog.pg_class c
 JOIN pg_catalog.pg_inherits i
 ON c.oid = inhrelid
 WHERE c.oid = <oid_of_partition>
And why I am writing about it? Because currently (2019/10) there isn’t much useful info about these functions in PG documentation – at least searches did not give me anything…

So here is my query to get partitioning info about table:
*/

select c.oid, c.relispartition,
       '"'||c.relnamespace::regnamespace::text||'"."'||c.relname||'"' as partition_name,
       partstrat,
       CASE WHEN partstrat='h' THEN 'HASH'
       WHEN partstrat='l' THEN 'LIST'
       WHEN partstrat='r' THEN 'RANGE' END as partition_by,
       partnatts as columns_in_key,
       partdefid,
       (select '"'||relnamespace::regnamespace::text||'"."'||relname||'"'
       from pg_class pc where pc.oid=ppt.partdefid)
       as default_partition_name,
       (select string_agg(attname,',')
       from pg_attribute pa
       where pa.attrelid=ppt.partrelid and pa.attnum=ppt.partattrs::text::smallint)
       as partition_key_column_name,
       pg_catalog.pg_get_expr( c.relpartbound, c.oid) as partition_values_orig,
       replace( replace( replace( replace( replace( replace(
            pg_catalog.pg_get_expr( c.relpartbound, c.oid)
            ,' 00:00:00','') ,'FOR VALUES FROM (''','') , ''') TO (''',';') ,''')',''), 'FOR VALUES IN (''', ''), ''',''', ';')
       as partition_values_updated,
       pg_catalog.pg_get_partition_constraintdef(c.oid) as partition_full_confition
from pg_class c
left join pg_partitioned_table ppt ON ppt.partrelid=c.oid
where c.oid= <table_oid>
