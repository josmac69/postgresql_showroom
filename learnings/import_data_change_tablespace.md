# Import really big export files into PostgreSQL + change tablespace during import

### Import really big file:

Suppose we have export from another pg database  in text format with size like 70+ GB. And we want to import it into database on machine with something like 16 GB of memory.

In situation like this it is very probable that attempt to decompress data file first will fail because of not enough memory.

Therefore we need to use decompression in command line and feed it into import tool.

gz file: `gunzip -c gzipped_file| psql -U my_user -d my_database`



### Change tablespace during import:

check lines with ‘tablespace’ string:
```
gunzip -c myfile.sql.gz|grep -i tablespace|grep -v "^-- "
```
Last grep removes comments which can contain tablespace name.
In result we must look especially for phrases like “TABLESPACE xxxx” in table definition or “SET default_tablespace = …”. These must be replaced. Especially if you want to place objects from default tablespace to some specific you need replace SET commands for default tablespace: SET default_tablespace = ”
These are always in import file.

replace tablespace name in pipe feed like this:
```
gunzip -c myfile.sql.gz|sed "s/SET default_tablespace = ''/SET default_tablespace = 'my_default'/g"|psql ....
```
if you find some different text just add another “sed” part with it.
