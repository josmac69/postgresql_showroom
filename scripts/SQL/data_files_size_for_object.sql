/*
Display / find / determine size of data files for tables / objects
You can do it directly from PostgreSQL using following query.
It will show you all objects in chosen database which have data files, tablespace,
location of tablespace, data file name with full path, size and dates.
Shows all types of sizes you can get from PostgreSQL.
*/

with pgdir as (select setting as _dir from pg_settings where name = 'data_directory'),
pgdefault as (select setting as _defdir from pg_settings where name = 'default_tablespace'),
datablock as (select setting::int as block_size from pg_settings where name like 'block_size'),
objects as (select
    c.oid as reloid,
    c.relname,
    c.relpages,
    case c.relkind
    when 'r' then 'ordinary table'
    when 'i' then 'index'
    when 'S' then 'sequence'
    when 'v' then 'view'
    when 'm' then 'materialized view'
    when 'c' then 'composite type'
    when 't' then 'TOAST table'
    when 'f' then 'foreign table'
    else c.relkind||' ?' end as relkind,
    coalesce(ts.spcname, 'default') as tablespacename,
    ts.oid as tablespaceoid,
    coalesce(coalesce(pg_tablespace_location(ts.oid), nullif(_dir,'')), _defdir) as tablespacelocation,
    pg_relation_filepath(c.oid) as _file
from pg_class c
left join pg_tablespace ts on c.reltablespace=ts.oid
join pgdir on true
join pgdefault on true),
pgfiles as (select
    reloid,
    relname,
    relkind,
    relpages,
    tablespacename,
    tablespaceoid,
    tablespacelocation,
    tablespacelocation||'/'||_file as _file,
    _file as _file1,
    (relpages/(1024*1024*1024/(select block_size from datablock)))+1 as data_files_count,
    string_to_array(replace(replace(pg_stat_file(_file)::text,'(',''),')',''),',') as _detail
from objects
where _file is not null)
select
    relname as object_name,
    relkind as object_type,
    relpages as object_pages,
    pg_size_pretty(pg_total_relation_size(reloid)) as object_pg_size,
    pg_size_pretty(pg_total_relation_size(reloid) - pg_relation_size(reloid)) as object_pg_external_size,
    tablespacename as tablespace_name,
    tablespacelocation as tablespace_directory,
    case when position('pg_tblspc' in _file)>0 then replace(_file, 'pg_tblspc/'||tablespaceoid||'/','') else _file end as data_file_name,
    data_files_count,
    _detail[1]::bigint*data_files_count as data_file_size_b,
    _detail[1]::bigint/1024/1024*data_files_count as file_size_mb,
    _detail[2]::timestamp as _last_accessed,
    _detail[3]::timestamp as _last_modified,
    _detail[4]::timestamp as _last_file_status_change_unix_only,
    _detail[5]::text as _file_creation_windows_only
from pgfiles
order by relpages desc;
