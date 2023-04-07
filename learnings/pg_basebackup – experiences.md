# pg_basebackup

* pg_basebackup version <10 does not allow streaming of WAL files during tar files so it is technically useful mainly for cloning of the database for replication. To use it for backups it is necessary to use it with pg-barman.
* pg_basebackp version 10+ has this repaired so you can create tar format backup with WAL logs catched. Which is really good for backup of huge databases (several TB and bigger).
* Reason for using plain pg_basebackup for backup of huge databases are:
  * Current version of pg-barman 2.3 (2017/12) has a bug while using pg_basebackup version 10 causing problems in catching of WAL logs.
  * pg_basebackup does not cause any problems with high load on database server and does not use any locks on tables
* To be able to backup huge databases (several TB and bigger) it is necessary to set 2 parameters on them high enough to ensure pg_basebackup will be able to stream all WAL logs. This is what I ended up with:
  * wal_keep_segments = 2048 # in logfile segments, 16MB each; 0 disables
  * wal_sender_timeout = 1200s # in milliseconds; 0 disables
    * This change can be done without restart of the PostgreSQL, just use `select pg_reload_conf();` in psql command line tool. In PG main log in /var/log/postgresql you can see if change was accepted.
    * Be aware this change will cost you at least 16 GB of space on the filesystem with PG main/pg_xlog (or pg_wal for pg10+) !!!
    * Generally I strongly warn against doing similar changes on Friday evening !!!  🙂
* Generally making tar format backup without gzip (parameter “-z”) is much quicker (like 3x quicker) although it costs you more disk space.
