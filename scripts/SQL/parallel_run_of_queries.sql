/*
To make things more clear here is first example of parallel run of functions in PostgreSQL using dblink.
This simplest solution presumes:
you have some limited list of tasks and/ or connections you need to run
you have HW powerful enough to run all tasks at once
*/

declare
    _rec record;
    _query text;
    _connection_name text;
    _connect_string text;
    _db_con text[]; --array will store connection names of opened connections
    _result text;
    _opened_connections text;
    _i int; --simple counter
    _error_text text;
begin
    for _rec in select <columns> from <list_of_tasks/connections> loop
        _connection_name := ...every connection must have unique name - use some incremented id etc....;
        _connect_string := ....set or construct connect string....;
        _query := ...set or construct query for this connection....;
        if (select coalesce(_connection_name = any (dblink_get_connections()), false)) then --check if connection with this name is already opened
            perform dblink_disconnect(_connection_name); --if connection name is opened we need to close it - this is important mainly during tests
        end if;
        perform dblink_connect(_connection_name, _connect_string);  --open unique connection
        _db_con := array_append(_db_con, _connection_name); -- add connection name into array
        result := dblink_send_query(_connection_name, _query); -- we send query into connection - function DOES NOT wait for result
    end loop;

    -- now we will retrieve results
    select dblink_get_connections() into _opened_connections;
    if coalesce(_db_con && _opened_connections, false) then  --if some connection from _db_con is opened then check results
        for _i in 1..array_upper(_db_con,1) loop --from 1 to number of items in _db_con
            begin
                select _dbresult from dblink_get_result(_db_con[_i]) as r(_dbresult text) into _result;
                --this statement will retrieve result for given connection - it WILL wait until connection returns result
                --therefore some long running connection will block this function
                --but for simple tasks this should not be a problem since you need to wait for all connections anyway

                perform ...if you need to do something with result...;
            exception when others then
                --if connection ended with error then this error will be now thrown into this function and we must catch it
                _error_text := 'Code='||sqlstate||', message='||sqlerrm;
                perform ...here some logging of error etc....;
            end;

            select dblink_get_connections() into _opened_connections;
            if coalesce(_db_con[_i] && _opened_connections, false) then  --if currently checked connection from _db_con is still opened then close it
                execute 'select dblink_disconnect('''||_db_con[_i]||''')';
            end if;

        end loop;
    end if;
end;