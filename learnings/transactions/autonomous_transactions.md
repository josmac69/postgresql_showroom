# Autonomous transaction in PostgreSQL
I think this is really very well known. I add it here only as a reminder.

* In Oracle you can define “pragma autonomous_transaction” to force your procedure make changes in data regardless of any other pending transaction. This is really useful when you need to log something – like log more information about environment in the moment of error etc.

* In PostgreSQL we can do the same with dblink command. DBLINK opens new connection into database which is independent on your present connection and can therefore be committed independently.
So your logging procedure can look like this:

``
create or replace function system_log(_error_message text) returns void as $$
begin
perform dblink_connect('pragma','dbname=....here_your_database_name....');
perform dblink_exec('pragma','insert into error_log_table values (_error_message);');
perform dblink_exec('pragma','commit;');
perform dblink_disconnect('pragma');
end;
$$ language plpgsql;
```
