# Export data into CSV format

Command “COPY” will do all the dirty job.
Attention – Examples are meant for Linux and contain variables which you have to set or substitute with values.

If data are small you will probably use directly unpacked form:

```
psql -U postgres -d ${database_name} -c "copy ${table_schema}.${table_name} to '${output_file_with_full_path}.csv' with delimiter ';' csv header force quote *;"
```

If data are big use this Linux command to – export data, pack it with gzip and save into file:

```
psql -U postgres -d ${database_name} -c "copy ${table_schema}.${table_name} to stdout with delimiter ';' csv header force quote *;" | gzip -c >${outputfile_with_full_path}.csv.gz
```
