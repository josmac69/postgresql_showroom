# Default “postgres” database – how to re-create it
* From time to time happens that someone pollutes default “postgres” database with some unwanted stuff like import of objects intended for some other database. Or it may even happen that someone drops it. If so you can easily create or re-create new default “postgres” database.

on Debian/Ubuntu:
```
sudo su postgres
psql -d someotherdatabase
\l+
# you will see list of all databases with sizes
# drop database postgres;
\q
# exit psql tool into command like again
createdb postgres
creates new postgres database
psql
\l+
# check databases again
\q
# exit psql
exit
# exit postgres user
```
