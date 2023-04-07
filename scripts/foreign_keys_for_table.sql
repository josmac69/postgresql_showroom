/*
in theory you could use following select to show / list all foreign keys for some table
together DDL of constraint definition.
*/

select
    att2.attname as "child_column",
    cl.relname as "parent_table",
    att.attname as "parent_column",
    pg_catalog.pg_get_constraintdef(con_oid) as "constraint_definition"
from
   (select
        unnest(con1.conkey) as "parent",
        unnest(con1.confkey) as "child",
        con1.confrelid,
        con1.conrelid,
        con1.oid as con_oid
    from
        pg_class cl
        join pg_namespace ns on cl.relnamespace = ns.oid
        join pg_constraint con1 on con1.conrelid = cl.oid
    where
        cl.relname = '...your_table_name....'
        and ns.nspname = '...your_schema...'
        and con1.contype = 'f'  --this means the type of constraint "foreign key"
   ) con
   join pg_attribute att on
       att.attrelid = con.confrelid and att.attnum = con.child
   join pg_class cl on
       cl.oid = con.confrelid
   join pg_attribute att2 on
       att2.attrelid = con.conrelid and att2.attnum = con.parent

/*
Praxis is not so trivial. DDL command for constraint you get from this
build-in function “pg_get_constraintdef” is slightly different from real full definition.

Therefore in reality only pg_dump is able to give you full useful DDL command for anything.
So if you for example need to create some script which should recreate some objects you are doomed to do it manually.

I am surprised that people in forums do not understand why could someone need simple way
to get reliable DDL commands from PostgreSQL.
*/