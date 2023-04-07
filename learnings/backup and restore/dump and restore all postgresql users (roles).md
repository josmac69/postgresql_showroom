* this is important first step if you migrate envirnment into completely new installation
  * all users must be available before you start to restore other objects
* dump all users on source database: `pg_dumpall -r > sourceroles.backup`
* restore all users on target database:
  * if postgresql is freshly installed you will have to switch to postgres user: `sudo su postgres`
  * restore under postgres user: `psql < sourceroles.backup`
