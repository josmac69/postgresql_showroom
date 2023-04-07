/*
List of columns and list of column definitions for dblink
This is just a very small and very simple candy – but sometimes it can save some nerves.
Sometimes you need to aggregate list of columns and list of
column definitions to use it in dynamic query for example for dblink etc.
*/

with srcdata as (
    select
    column_name, data_type
    from information_schema.columns col where table_schema = '...your_schema...' and table_name = '...your_table...'
    order by ordinal_position
)
select string_agg(column_name,', ') as _column_list,
'('||string_agg(column_name||' '||data_type,', ')||')' as _column_definitions
from srcdata