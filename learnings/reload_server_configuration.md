# Reload server configuration
You can use several ways to do it:

* in pgAdmin – right click on connection and choosing “Reload configuration”
* in psql / pgAdmin / any db gui – using SQL: `select pg_reload_conf();`
* from Linux – as postgres (if your PGDATA variable is set): `pg_ctl reload`
  * from Linux – as postgres (if your PGDATA variable is not set): `pg_ctl reload -D /path/to/your/data/directory`
  * if PGDATA is missing you will see error message: pg_ctl: no database directory specified and environment variable PGDATA unset
    * if so use: `ps -ef|grep postgres` - to see your postgres process – look for parameter “-D” in process command line – it shows you data directory – for example /mydata/pgdata
    * so use it in pg_ctl command: `pg_ctl reload -D /mydata/pgdata`
