-- Find comments on database objects
-- If you need to check which of your objects have comments you can use this select:

SELECT  ns.nspname    AS schema_name
       ,c.relname     AS table_name
       ,a.attname     AS column_name
       ,d.description AS "comment"
FROM pg_description d
JOIN pg_class c
ON d.objoid = c.oid
JOIN pg_namespace ns
ON c.relnamespace = ns.oid
LEFT JOIN pg_attribute a
ON d.objoid = a.attrelid AND d.objsubid = a.attnum;
