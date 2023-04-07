/*
Add indexes to partitions
When you develop some changes it may happen you need to add new indexes to all existing partitions
of some parent table. It happened to me several times already. Therefore I put here this small pl/pgsql
script which can help with it. Script creates indexes using dblink so it can be canceled any time.
And if you restart it it checks if index already exists.
For indexes on full columns check of existing indexes works without problems.
There could be some problems with indexes on expressions.
It worked for some of them but not for all.
So check if it does not create duplicate indexes.
*/

do $$
declare
    _tab record;
    colnames text;
    querymask text;
    query text;
    _col record;
    indexexists int;
    ret text;
begin

    for _tab in (
    select
    relnamespace::regnamespace::text as schemaname,
    relnamespace::regnamespace::text||'.'||relname as fullname,
    relname as shortname
    from pg_class where oid in (
    select inhrelid from pg_inherits
    where inhparent::regclass::text like '%...your_parent_table...')
    order by 2 desc) loop

        querymask := 'create index '||_tab.shortname||'_${INDEXNAME} on '||_tab.fullname||' ${COLUMNS}';
        raise notice 'querymask: %', querymask;

        for _col in (
        select * from (
        values('index1','(col1, col2)'),
        ('index2','(col2, col3)'),
        ('index3','(col4)') ) as t(indexname, colnames)
        ) loop
            select count(*) into indexexists from pg_indexes i
            where i.schemaname=_tab.schemaname and
            i.tablename=_tab.shortname and
            i.indexname=_tab.shortname||'_'||_col.indexname;

            if indexexists = 0 then
                query := replace(querymask, '${INDEXNAME}', _col.indexname);
                query := replace(query, '${COLUMNS}', _col.colnames);
                raise notice 'query: %', query;
                select dblink_exec('dbname='||current_database(),query) into ret;
                raise notice 'result: %', ret;
            end if;
        end loop;
    end loop;

end;
$$ language plpgsql;
