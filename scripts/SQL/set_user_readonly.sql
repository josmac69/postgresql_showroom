do $$
declare
    _schema text;
    _query text;
    _user text := '...your reader user name...';
begin

    if not exists (select rolname from pg_roles where rolname=_role) then
        _query := 'CREATE ROLE '||_role||' NOINHERIT;';
        raise notice 'query: %', _query;
        execute _query;
    end if;

    _query := 'ALTER DEFAULT PRIVILEGES REVOKE ALL ON TABLES FROM '||_user||';';
    raise notice 'query: %', _query;
    execute _query;

    _query := 'ALTER DEFAULT PRIVILEGES GRANT select ON TABLES TO '||_user||';';
    raise notice 'query: %', _query;
    execute _query;

    for _schema in (select nspname from pg_namespace) loop

        _query := 'GRANT USAGE ON SCHEMA '||_schema||' TO '||_user||';';
        raise notice 'query: %', _query;
        execute _query;

        _query := 'ALTER DEFAULT PRIVILEGES IN SCHEMA '||_schema||' GRANT SELECT ON TABLES TO '||_user||';';
        raise notice 'query: %', _query;
        execute _query;

        _query := 'GRANT select ON all TABLES in schema '||_schema||' TO '||_user||';';
        raise notice 'query: %', _query;
        execute _query;

    end loop;

end; $$ language plpgsql;
