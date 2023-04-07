# error: duplicate key value violates unique constraint pg_type_typname_nsp_index

If you see `error: duplicate key value violates unique constraint "pg_type_typname_nsp_index"`
then you most probably tried to restart “create table” command and previous process is still running.

This constraint is an unique index on table `pg_type` and each table you create has its own pseudo type in this table. So your restarted “create table” processes tried to insert the same new type which already exists due to old still running process but target table was not created yet therefore you did not get message “table already exists” because this table is still not commited.

So if really need to restart process you need to kill old process first using `pg_terminate_backend()` function.
