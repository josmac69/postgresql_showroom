# pg_restore

* restore the whole database from backup file in custom format:
```
pg_restore --username "user_name" --no-password --format custom --verbose -d "database_name" "file_name.backup"
```
* restore the whole database from backup in directory format:
```
pg_restore --username "user_name" --no-password --format directory --jobs 3 --verbose -d "database_name" "directory_name"
```
* restore only one schema:
```
pg_restore --username "user_name" --no-password --format custom --verbose --schema "schema_name" -d "database_name" "file_name.backup"
```

* restore from more files (on Linux – in directory with backup files):
```
for f in *.backup; do echo $f; pg_restore -U postgres -d "database_name" $f; done
```
* restore + drop and recreate object + suppress error messages when object does not exist
```
pg_restore --username "user_name" --no-password --format custom --verbose -d "database_name" --clean --if-exists "file_with.backup"
```

If pg_restore gives your error like this: pg_restore: [archiver (db)] connection to database “…” failed: FATAL: Ident authentication failed for user “….” about “peer” method then you need:

* do the whole operation under this user
* or run command using “sudo -u username here_goes_whole_command”
* or to make change in your pg_hba.conf file – you must change your “local” unix socket and IPv6 for ::1/128 METHOD columns to “trust” (without logging) or “md5” (logging with password) and reload configuration.

## Restore with create database

root@postgresql15:/# pg_restore -U postgres -d postgres -C -F d -v dumpdir

pg_restore: connecting to database for restore
pg_restore: creating DATABASE "test"
pg_restore: connecting to new database "test"
pg_restore: creating TABLE "public.testtest"
pg_restore: creating SEQUENCE "public.testtest_id_seq"
pg_restore: creating SEQUENCE OWNED BY "public.testtest_id_seq"
pg_restore: creating DEFAULT "public.testtest id"
pg_restore: processing data for table "public.testtest"
pg_restore: executing SEQUENCE SET testtest_id_seq
pg_restore: creating CONSTRAINT "public.testtest testtest_pkey"

