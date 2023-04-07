/*
Find biggest tables / database objects over all databases based on data file size
This query shows you biggest database objects over all databases – size is taken from
size of its data file therefore you see how big object on your disk really is:
*/

with dbs as (select datname as databasename, lnk.* from pg_database db
join lateral (select * from dblink('dbname='||db.datname,
$$with pgdir as (select setting as _dir from pg_settings where name = 'data_directory'),
objects as (select c.relname,
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
ts.spcname as tablespacename,
pg_tablespace_location(ts.oid) as tablespacelocation,
_dir||'/'||pg_relation_filepath(c.oid) as _file
from pg_class c, pgdir, pg_tablespace ts
where c.reltablespace=ts.oid),
pgfiles as (select relname, relkind, tablespacename, tablespacelocation, _file,
string_to_array(replace(replace(pg_stat_file(_file)::text,'(',''),')',''),',') as _detail
from objects
where _file is not null)
select
relname, relkind, tablespacename, tablespacelocation,
_file,
round(_detail[1]::numeric/1024/1024,2) as _size_mb,
_detail[2]::timestamp as _last_accessed,
_detail[3]::timestamp as _last_modified,
_detail[4]::timestamp as _last_file_status_change_unix_only,
_detail[5]::text as _file_creation_windows_only
from pgfiles$$)
as t(relname text, relkind text, tablespacename text, tablespacelocation text,
_file text, _size_mb numeric, _last_accessed timestamp, _last_modified timestamp,
_last_file_status_change_unix_only timestamp, _file_creation_windows_only text)) lnk on true
where db.datistemplate is false )
select *
from dbs
order by _size_mb desc;
