# Add new disk and tablespace to PostgreSQL master and replica
* This text may be “too obvious” but it also can save some nerves to someone 🙂

I might need it if you have PostgreSQL mater and replica(s) virtual instances with streaming replication and suddenly you face a problem with disk being too full and (as usual) you must do it under normal traffic without causing any interruptions.

Scenario was used for Google Compute Engine but it is very similar to other clouds:

### On both machines
* Add exactly the same new disks (type, size) to master and all replica(s).
* Format them and mount them on every instance under mounting points with exactly the same name
* Create directory for PostgreSQL table space on mounted disk with exactly the same name on all instances
* Target directory for PostgreSQL table space must have owner “postgres:postgres” so set it using `sudo chown postgres:postgres directory` on all instances

### On master only
* in PostgreSQL create new table space in target location using `CREATE TABLESPACE` command
* Check replica(s) – creation of tablespace is replicated so it must be successful on all replicas. If not then you have a problem and you must found why particular replica did not fulfilled the command. Once you fix it drop tablespace on master and create it again (command does not have `if not exists` clause).

Warning – based on my own experience you must be very cautious about moving tables into new tablespace. Command `ALTER TABLE … SET TABLESPACE …` can cause huge Disk I/O on replica and delay recovery so replica can stop replication. Because wal log receiver will not be able to store new wal logs quickly enough – unless you have wal segments on different disk.

* Moving only one table at a time is definitely advisable + make pause after it to give replica(s) enough time to finish everything.

* Of course if you properly set archiving on master, ssh connection and recovery.conf on replica then if replication stops on some replica you will just restart postgresql on replica and everything should be OK.

* If you have table partitioned and you just want to redirect new partitions to the new tablespace then easiest way is to set `default_tablespace` in config file to new tablespace and reload configuration – “select pg_reload_conf();”.

* Of cause small “sanity check” is always a good idea – try to create some testing table and check if it was created in new tablespace….

