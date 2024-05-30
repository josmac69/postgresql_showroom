-- This script lists all available operator classes for the GIN index method.
-- For other index methods, replace 'gin' with the desired method name.
-- Variants of methods are listed in the pg_am catalog table.

-- available methods
select amname from pg_am order by 1;

-- available operator classes per selected method
SELECT am.amname AS index_method,
    opc.opcname AS opclass_name,
    opc.opcintype::regtype AS indexed_type,
    opc.opcdefault AS is_default
FROM pg_am am, pg_opclass opc
WHERE opc.opcmethod = am.oid
    AND am.amname = 'gin'
ORDER BY index_method, opclass_name;