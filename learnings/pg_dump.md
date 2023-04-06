# pg_dump

* dump the whole database (custom format):

```
pg_dump --username "user_name" --no-password   --format custom --verbose --file "file_name.backup" "database_name"

```

* dump only one schema:

```
pg_dump --username "user_name" --no-password --format custom --verbose --file "file_name.backup" --schema "schema_name" "database_name"
```

* dump the whole database into directory format (3 dump processes):

```
pg_dump --username "user_name" --no-password --format directory --jobs 3 --verbose --file "directory_name" "database_name"
```

* dump one table (into one file with custom format):

```
pg_dump --username "user_name" --no-password --format custom --table "schemaname.tablename" --verbose --file "file_name.backup" "database_name"
```

* dump only structures (without data) into plain sql format:

```
pg_dump --username "user_name" --no-password --format plain --verbose --schema-only --file "file_name.backup" "database_name"
```
