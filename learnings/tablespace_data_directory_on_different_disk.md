# Move PostgreSQL tablespace / data directory to another disk

I had to face several time situation like this – existing disk is suddenly too small and we need to move to bigger one.
And for some reason there is no time to do it properly – like stopping database for several hours and migrating data to another machine etc.
I am well aware that following scenarios are ugly – but I already had to face them in real live and there was no other way around at that moment…

Scenarios can be:
(scenarios presume that partition table + partition on new disk exists, disk is mounted and writable – do not forget to add new disk into /etc/fstab
second presumption you can afford only very short downtime)

1. We just add a new disk and want PostgreSQL to create new tables/ indexes on it leaving existing objects where they are
   * be aware that this works only if you for example only add new partitions and old ones are not growing
   * create some directory on new disk for new partition for pg data
   * create new tablespace in postgresql with location on new disk in directory you created
   * set parameter “default_tablespace” to new tablespace globally + reload configuration
   * check settings of “default_tablespace” on databases – change it to new tablespace
2. We need to move existing data to new disk from old one
   * first steps are the same as in scenario 1
   * how to move existing data depends on pg version you have:
     * in pg 9.3 or older you need to alter all tables and indexes to new tablespace:
       * alter table … set tablespace ….
       * alter index … set tablespace ….
     * in pg 9.4 or higher you can use nice new commands:
       * alter table all in tablespace …oldone… set tablespace …newone…
       * the same with indexes
   * be prepared that moving of data can take dozens of minutes or even hours
   * do not forget to do it on all databases
   * if you have to alter tables/ indexes one by one it is better to it is separate transactions for example using dblink – otherwise your WAL log can grow too much and crash the database if there is no space left on disk
   * if there is no need to remove old disk then you are done (and lucky)
   * if you need to completely move all pg stuff to new disk then you will have to:
     * check remaining objects in pg directories on old disk – to now what you will have to move
     * stop postgresql
     * login as postgres and move remaining objects on new disk – to be safe do not move them into existing directories, it is better to create special ones for them
     * check directory pg_tblspc in your PGDATA directory – contains symbolic links for all tablespaces – if some link points to directories on old disk delete it and create a new one pointing to proper directory on new disk
     * if you must move also your whole PGDATA directory do not forget to change its location in postgresql.conf
     * start postgresql
