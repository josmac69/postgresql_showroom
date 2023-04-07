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