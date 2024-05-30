-- https://www.postgresql.org/docs/current/indexes-opclass.html

-- check dependency of indexes on extensions

SELECT
    c.relname AS index_name,
    e.extname AS extension_name
FROM
    pg_depend d
JOIN
    pg_class c ON d.objid = c.oid
JOIN
    pg_extension e ON d.refobjid = e.oid
WHERE
    c.relkind = 'i';

-- dependencies of indexes on operator classes
SELECT
    c.relname AS index_name,
    opc.opcname AS operator_class
FROM
    pg_depend d
JOIN
    pg_class c ON d.objid = c.oid
JOIN
    pg_opclass opclass ON d.refobjid = opclass.oid
WHERE
    c.relkind = 'i';

--- dependencies of operator classes on extensions
SELECT
    opc.opcname AS operator_class,
    e.extname AS extension_name
FROM
    pg_depend d
JOIN
    pg_opclass opc ON d.objid = opc.oid
JOIN
    pg_extension e ON d.refobjid = e.oid
WHERE
    d.classid = 'pg_opclass'::regclass;


---
WITH index_dependencies AS (
    SELECT
        c.relname AS index_name,
        e.extname AS extension_name
    FROM
        pg_depend d
    JOIN
        pg_class c ON d.objid = c.oid
    JOIN
        pg_extension e ON d.refobjid = e.oid
    WHERE
        c.relkind = 'i'
), opclass_dependencies AS (
    SELECT
        c.relname AS index_name,
        opc.opcname AS operator_class
    FROM
        pg_depend d
    JOIN
        pg_class c ON d.objid = c.oid
    JOIN
        pg_opclass opc ON d.refobjid = opc.oid
        WHERE
            c.relkind = 'i'
), extension_dependencies AS (
    SELECT
        opc.opcname AS operator_class,
        e.extname AS extension_name
    FROM
        pg_depend d
    JOIN
        pg_opclass opc ON d.objid = opc.oid
    JOIN
        pg_extension e ON d.refobjid = e.oid
    WHERE
        d.classid = 'pg_opclass'::regclass
)
SELECT
    *
FROM
    index_dependencies
UNION ALL
SELECT
    *
FROM
    opclass_dependencies
UNION ALL
SELECT
    *
FROM
    extension_dependencies;

