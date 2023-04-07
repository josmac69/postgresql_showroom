/*
System information functions - to see all results at once
*/
select 'current_database()' as _command, current_database() as _result, 'name of current database' as _description
union all
select 'current_schema()', current_schema(), 'name of current schema'
union all
select 'current_schemas(true)', cast(current_schemas(true) as text), 'names of schemas in search path, optionally including implicit schemas'
union all
select 'current_user', current_user, 'user name of current execution context'
union all
select 'current_query()', cast(current_query() as text), 'text of the currently executing query, as submitted by the client (might contain more than one statement)'
union all
select 'pg_backend_pid()', cast(pg_backend_pid() as text), 'Process ID of the server process attached to the current session'
union all
select 'inet_client_addr()', cast(inet_client_addr() as text), 'address of the remote connection'
union all
select 'inet_client_port()', cast(inet_client_port() as text), 'port of the remote connection'
union all
select 'inet_server_addr()', cast(inet_server_addr() as text), 'address of the local connection'
union all
select 'inet_server_port()', cast(inet_server_port() as text), 'port of the local connection'
union all
select 'pg_my_temp_schema()', cast(pg_my_temp_schema() as text), 'OID of session''s temporary schema, or 0 if none'
union all
select 'pg_postmaster_start_time()', cast(pg_postmaster_start_time() as text), 'server start time'
union all
select 'pg_conf_load_time()', cast(pg_conf_load_time() as text), 'configuration load time'
union all
select 'session_user', cast(session_user as text), 'session user name'
union all
select 'version()', version(), 'PostgreSQL version information';
