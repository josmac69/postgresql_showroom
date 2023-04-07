/*
Drop all versions of a function
Do you need to drop all existing versions of some function
without knowing anything about parameters?
Try this
*/

do $$
declare
_rec record;
begin

for _rec in select 'drop function if exists '||ns.nspname||'.'||p.proname||'('||pg_catalog.pg_get_function_arguments(p.oid)||');' as _command
from pg_proc p join pg_namespace ns on p.pronamespace=ns.oid where ns.nspname='...your_schema...' and p.proname = '...your_function...' loop
raise notice 'command: %', _rec._command;
execute _rec._command;
end loop;

end
$$
