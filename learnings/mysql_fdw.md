# Extension mysql_fdw
This extension allows you to connect from PostgreSQL with read/write capability to mySQL database.

Install on Ubuntu (you need to have pg repos allowed) using:

```
sudo apt-get install postgresql-9.5-mysql-fdw
sudo apt-get install libmysqlclient-dev
```
To create foreign object basically follow instructions of Github. But you do not need to create all foreign tables manually. In PostgreSQL 9.5 you can use command IMPORT FOREIGN SCHEMA.

But there is one problem with  enum data types extracted from mySQL schema. mysql_fdw tries to create them as public types in PostgreSQL which does not work because mySQL stores text based enum types as text. Therefore after foreign tables in PostgreSQL are created I change types of these columns to type. If you also want to you can use script like this:

```
do $$
declare
_command text;
begin
for _command in (select concat('alter foreign table ',table_schema,'.',table_name,' alter column "',column_name,'" type text;') as _command from information_schema.columns where data_type = 'USER-DEFINED') loop
raise NOTICE '%', _command;
execute _command;
end loop;
end;
$$ language plpgsql;
```

Otherwise it works OK and you can enjoy manipulating data in mySQL using powerful function of PostgreSQL.