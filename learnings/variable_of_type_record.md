# How to find column names of variable type record in PL/pgSQL
Language PL/pgSQL has one big disadvantage when you work with variable of type “record”. You cannot easily iterate over record columns because in this language record is not handled as “hashed” record like in JavaScript or Python etc.

Fortunately with new JSON functions PostgreSQL we now have possibility to overcome it – at least for tables. So we can do some manipulations with data from the table without necessity to hard code column names.

Here is one example how to do it – shows table columns as separate rows:

```
with srcdata as ( select tablename as _row_key, row_to_json(t) as _row from pg_tables t where tablename in ( 'pg_class', 'pg_am')),
columns as (select json_object_keys(_row) as _column from (select * from srcdata limit 1) a )
select _row_key, _column, _row->_column as _value from srcdata, columns
```
