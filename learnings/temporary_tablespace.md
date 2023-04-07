# Temporary tablespace - notes from tests

Lately I did some research and tests regarding special dedicated temporary tablespace so here is small summary of what I have found:

(I described it on [stackoverflow](https://web.archive.org/web/20210919013651/https://stackoverflow.com/questions/48152257/can-google-cloud-local-ssd-be-used-for-postgresql-temp-tablespace/48166314#48166314) too)

* PostgreSQL tablespace is just a directory – no big deal.
* Plus – if you will use it only as temporary table space there will be no persistent file left when you shutdown database.
* temporary tablespace is used for 2 types of objects – temporary tables and temporary files generated for example for huge sorts

So you can create tablespace for temp tables on any location you want and then go to this location and check directory structure to see what PG created.

PG will show you only tablespace main directory:

- both commands \db+ in psql or `select oid, spcname, pg_tablespace_location(oid) from pg_tablespace;` work the same way.

My example (temporary tables):

* I used /tempspace/pgtemp as presumed mounting point
* `CREATE TABLESPACE p_temp OWNER xxxxxx LOCATION ‘/tempspace/pgtemp’;` created in my case structure `/tempspace/pgtemp/PG_10_201707211`
* I set `temp_tablespaces = ‘pg_temp’` in postgresql.conf and reloaded configuration.
* When I used `create temp table ….` PG added another subdirectory – `/tempspace/pgtemp/PG_10_201707211/16393` = oid of schema – but this does not matter for temp tablespace because if this subdirectory will be missing PG will create it.
* PG created in this subdir files for temp table.
* When I closed this session files for temp table were gone.

Now I stopped PG and tested what would happened if directories will be missing:

* I deleted `PG_10_201707211` with its subdir
* I started PG and log showed message `LOG: could not open tablespace directory “pg_tblspc/166827/PG_10_201707211”: No such file or directory`
  * but PG started anyway
* I tried to create temp table – I got error message `ERROR: could not create directory “pg_tblspc/166827/PG_10_201707211/16393”: No such file or directory SQL state: 58P01`
* Now (with running PG) I issued these commands in OS:
  * `sudo mkdir -p /tempspace/pgtemp/PG_10_201707211`
  * `sudo chown postgres:postgres -R /tempspace/pgtemp`
  * `sudo chmod 700 -R /tempspace/pgtemp`
* I tried to create temp table again and insert and select values and everything worked OK

So conclusion is – since PG tablespace is no “big magic” just directories you can simply create bash script running on linux startup which will check (and create and / or mount if necessary) your special location and create necessary directories for PG temp tablespace.

This way you can ensure temporary tablespace on Google Compute Engine local SSDs or on RAM disk. But in case of RAM disk you must be aware of presumed size of temp tables to fit them into RAM disk.

Note about temporary sort files:

* They are created in special directory called “pgsql_tmp” under temporary tablespace directory. Name of each files starts with “pgsql_tmp” and has some number as suffix.
* These temporary files as used only during current transaction and are deleted after statement is processed. If you find some old pg temporary files under tablespace directory and you made sure that no long running transaction is still using them then it means process, which created these files, crushed, transaction was not closed correctly and file were not deleted. PostgreSQL already “forgot” about them. So you will have to delete them manually.
