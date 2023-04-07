# SQL injection in PostgreSQL
There are already some very good texts about it on web and I do not want to “steal” credit from them:

Detecting PostgreSQL SQL injection (does not work anymore)
[Postgres SQL injection cheat sheet](https://pentestmonkey.net/cheat-sheet/sql-injection/postgres-sql-injection-cheat-sheet)

There are just some of my experiencies:

* If you can use prepared statements instead of dynamic queries
* If you must use dynamic queries (which can be more often case) try to follow these rules:
* If you can, always use list of values not allowing manually typed value – even for numbers. In many cases user can choose from some arbitrary set of distinct values like for age, year etc. and it will prevent mistakes and unrealistic values.
* If you must allow “raw” input value then
* If it is numeric, always validate it – simplest validation is cast from string to number
* If it is string then wrap it using “quote_literal” or “quote_nullable” functions
You can test on this simple code. Of course do not try anything destructive 🙂

```
do $$
declare
    _t text;
    _q text;
    _r text;
    _n numeric;
    _des text;
    _querymask text;
begin

    -- query
    _querymask := 'select tableowner from pg_tables where tablename=';

    -- injected text
    _t := 'NULL; select current_database();';

    _des := 'query without quote function';
    _q := _querymask||_t;
    raise notice '%: %', _des, _q;
    execute _q into _r;
    raise notice 'returned value: %', _r;

    _des := 'query with quote function';
    _q := _querymask||quote_nullable(_t);
    raise notice '%: %', _des, _q;
    execute _q into _r;
    raise notice 'returned value: %', _r;

    -- query
    _querymask := 'select relname from pg_class where oid=';

    --test with numeric value
    _t := '0; select current_database();';

    _des := 'query without testing input for numeric validation';
    _q := _querymask||_t;
    raise notice '%: %', _des, _q;
    execute _q into _r;
    raise notice 'returned value: %', _r;

    _des := 'query with testing input for numeric validation';
    begin
        _q := _querymask||cast(_t as numeric);
        raise notice '%: %', _des, _q;
        execute _q into _r;
        raise notice 'returned value: %', _r;
    exception
        when invalid_text_representation then
        raise notice 'invalid input for numeric value';
    end;

end;
$$ language plpgsql;
```