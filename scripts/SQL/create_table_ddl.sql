/*
How to get DDL for table from PostgreSQL
Posted on 2015-06-15 | By Admin | No comments
So many people in PostgreSQL forums and mail lists do not understand why the hell should someone
need to get DDL for table directly in PL/pgSQL. Everyone keeps recommend pg_dump.
Well if you are one of them just skip this text.

On the other hand if you also have this problem maybe this small procedure could help you.
It gives you column definitions / or inheritance, all constraints and foreign keys, tablespace and indexes.

It is not at all nice and clever but it works and can save you some effort.
And you can expand it.
*/

create or replace function config.get_table_ddl (_table_name text)
returns text as
$body$
declare
    --input = schema.table_name

    _table_ddl text;
    _tmp_ddl text;
    _rec record;
    _child_table boolean := false;
begin
    if exists (select * from information_schema.tables t where table_schema||'.'||table_name=lower(_table_name)) then
        raise debug 'table found: %', _table_name;

        _table_ddl := 'CREATE TABLE '||_table_name||' (
                ';

        --columns -- only if table is not child table with inheritance
        _tmp_ddl:='';
        if exists (select inhparent::regclass from pg_inherits where inhrelid=_table_name::regclass) then
            --inheritance
            _child_table:=true;
        else
            --columns
            with srcdata as (
            SELECT a.attname ||' '|| format_type(a.atttypid, a.atttypmod) ||
                case when a.attnotnull then ' NOT NULL' else ' ' end as _def
                FROM pg_attribute a
                WHERE attrelid=_table_name::regclass and a.attstattarget = -1
                order by attnum
                )
            select string_agg(_def,',
            ') as _ddl into _tmp_ddl
            from srcdata;
        end if;

        if _tmp_ddl is not null then
            _table_ddl:= _table_ddl||_tmp_ddl;
        end if;

        --constraints
        _tmp_ddl:='';
        with srcdata as (
            select 'CONSTRAINT '||conname||' '||pg_catalog.pg_get_constraintdef(oid) as _ddl
            from pg_constraint where conrelid=_table_name::regclass
            order by case contype when 'p' then '1' when 'f' then '2'||conname else '3' end
            )
        select string_agg(_ddl,',
        ') as _ddl into _tmp_ddl
        from srcdata;

        if _tmp_ddl is not null then
            _table_ddl:= _table_ddl|| case when not _child_table then ',
            ' else ' ' end ||_tmp_ddl;
        end if;

        _table_ddl:= _table_ddl || ')
        ';

        if _child_table then
            select 'INHERITS ('|| inhparent::regclass||')' into _tmp_ddl
            from pg_inherits
            where inhrelid=_table_name::regclass;
            _table_ddl:=_table_ddl||_tmp_ddl;
        end if;

        _table_ddl:= _table_ddl ||'
        WITH (
            OIDS=FALSE
        )';

        _tmp_ddl:='';
        select
        case when tablespace is not null then 'TABLESPACE '||t.tablespace
        else ' ' end as _ddl into _tmp_ddl
        from pg_tables t
        where schemaname||'.'||tablename = _table_name;

        if _tmp_ddl is not null then
            _table_ddl := _table_ddl||'
            '||_tmp_ddl||';';
        end if;

        _tmp_ddl:='';
        select indexdef||' tablespace '||tablespace as _ddl into _tmp_ddl
	from pg_indexes
	where schemaname||'.'||tablename = _table_name;

        if _tmp_ddl is not null then
            _table_ddl := _table_ddl||'

            '||_tmp_ddl||';';
        end if;

    end if;

    raise debug '_table_ddl= %', _table_ddl;
    return _table_ddl;
end
$body$
language plpgsql volatile
 cost 100;
