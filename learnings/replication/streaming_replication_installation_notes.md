# Streaming replication on PostgreSQL 9.x – installation notes

Comment from website to this description:
Don’t use scp as the archive command but use something like rsync -a instead. scp is not atomic which means that you will eventually get unlucky and restore_command on the slave will read an incomplete WAL file resulting in broken replication.

***

To create new replica from master is in PostgreSQL much easier then in MySQL. In MySQl you have to flush tables on master with read lock and make backup. Which means during backup users cannot insert/update data. In PostgreSQL you can use pg_basebackup tool. It runs on future replica, creates backup of the given master using snapshot for current position in WAL log. Thanks to snapshot users can use master database in normal way during run of pg_basebackup.

Important files for replication (Debian):

* /var/lib/postgresql/9.x/main/recovery.conf
* /etc/postgresql/9.x/main/postgresql.conf


### Settings in postgresql.conf (master):
```
wal_level = hot_standby
archive_mode = on
archive_command
simple archive command with direct copy:
archive_command = ‘test ! -f /data/pgarchivedir/%f && cp %p /data/pgarchivedir/%f’
archiving to more sources using script:
archive_command = ‘/data/postgresql/pg_default/main/pg_archive_wal.sh “%p” “%f” >> /data/postgresql/pg_default/main/pg_archive_wal.log’
example of script see in other article
max_wal_senders = 10 #(must be higher then number of replicas)
wal_sender_timeout = 600s
```

### Settings in postgresql.conf (replica):
```
hot_standby = on
```

#### Content of “recovery.conf” file (replica):
```
standby_mode = 'on'
primary_conninfo = 'user=.... password=..... host=xxx.xxx.xxx.xxx port=5432 sslmode=prefer sslcompression=1 krbsrvname=postgres'
restore_command = 'scp postgres@xxx.xxx.xxx.xxx:/path/to/archives/%f %p'
```

* “restore_command” must be able to reach archived WAL logs. You can use “scp” command to copy logs from master to the replica. But do not forget to test this command under postgres user. If you have special ssh port (not 22) do not forget to add “-P xxxx” after scp.
* File recovery.conf must have owner postgres:postgres, permissions 600.
* If your replica stops receiving WAL logs you will see errors like this one in /var/log/postgresql/postgresql-x.x-main.log:

```
2017-xx-xx 08:38:24 UTC [20428-1] LOG: started streaming WAL from primary at CA6/56000000 on timeline 1
2017-xx-xx 08:38:24 UTC [20428-2] FATAL: could not receive data from WAL stream: ERROR: requested WAL segment 0000000100000CA600000056 has already been removed
```

If you will have some incident and your replica stops to receive logs from the master and gets out of sync you simply restart postgresql on your replica. After restart you will see in processes on replica that recovery is actually copying missing logs from archive on the master and applying them:
```
postgres 20512 1 0 08:38 ? 00:00:00 /usr/lib/postgresql/9.5/bin/postgres -D /var/lib/postgresql/9.5/main -c config_file=/etc/postgresql/9.5/main/postgresql.conf
postgres 20513 20512 18 08:38 ? 00:00:07 postgres: 9.5/main: startup process waiting for 0000000100000CA600000071
postgres 20518 20512 0 08:38 ? 00:00:00 postgres: 9.5/main: checkpointer process
postgres 20519 20512 0 08:38 ? 00:00:00 postgres: 9.5/main: writer process
postgres 21350 20512 0 08:39 ? 00:00:00 postgres: 9.5/main: stats collector process
postgres 21506 20513 0 08:39 ? 00:00:00 sh -c scp -P xxxxx postgres@xxx.xxx.xxx.xxx:/data/archive/0000000100000CA600000071 pg_xlog/RECOVERYXLOG
postgres 21507 21506 0 08:39 ? 00:00:00 scp -P xxxxx postgres@xxx.xxx.xxx.xxx:/data/archive/0000000100000CA600000071 pg_xlog/RECOVERYXLOG
postgres 21508 21507 0 08:39 ? 00:00:00 /usr/bin/ssh -x -oForwardAgent=no -oPermitLocalCommand=no -oClearAllForwardings=yes -p xxxxx -l postgres -- xxx.xxx.xxx.xxx scp -f /data/archive/0000000100000CA600000071
As you can see – scp command ships logs into pg_xlog/RECOVERYXLOG and the same log is then applied into database (see “startup process waiting for …”.
```

After restart you will see in your log lines like this one:

```
2017-xx-xx 08:38:38 UTC [20513-45] LOG: restored log file "0000000100000CA5000000EA" from archive
```

When all missing not automatically received logs are copied and applied postgresql returns to the normal run. In log you will see:
```
2017-xx-xx 08:49:26 UTC [20513-2009] LOG: restored log file "0000000100000CAD00000095" from archive
scp: /data/archive/0000000100000CAD00000096: No such file or directory
2017-xx-xx 08:49:26 UTC [1091-1] LOG: started streaming WAL from primary at CAD/95000000 on timeline 1
```
And in processes:
```
postgres 1091 20512 8 08:49 ? 00:00:16 postgres: 9.5/main: wal receiver process streaming CAD/99681AC8
postgres 20512 1 0 08:38 ? 00:00:00 /usr/lib/postgresql/9.5/bin/postgres -D /var/lib/postgresql/9.5/main -c config_file=/etc/postgresql/9.5/main/postgresql.conf
postgres 20513 20512 12 08:38 ? 00:01:47 postgres: 9.5/main: startup process recovering 0000000100000CAD00000099
postgres 20518 20512 4 08:38 ? 00:00:35 postgres: 9.5/main: checkpointer process
postgres 20519 20512 0 08:38 ? 00:00:00 postgres: 9.5/main: writer process
postgres 21350 20512 0 08:39 ? 00:00:00 postgres: 9.5/main: stats collector process
```

### pg_basebackup usage:
```
sudo service postgresql stop

sudo mkdir /pg_main_backup
sudo chmod 777 /pg_main_backup/

sudo su postgres
cd /var/lib/postgresql/9.x/main
mv * /pg_main_backup
pg_basebackup -h xxx.xxx.xxx.xxx -D /var/lib/postgresql/9.x/main -U replicator -P --xlog-method=stream
### will show progress and ship necessary xlogs
```
useful links:
https://opensourcedbms.com/dbms/point-in-time-recovery-pitr-using-pg_basebackup-with-postgresql-9-2/
https://blog.sleeplessbeastie.eu/2016/02/15/how-to-perform-base-postgresql-backup-using-pg_basebackup-utility/


### Pause / restart replication:

* stop (pause) replication: `select pg_xlog_replay_pause();`
* start replication: `select pg_xlog_replay_resume();`
* check status of replication: `select pg_is_xlog_replay_paused();`

### Changes in streaming replication in PostgreSQL 9.6
Lately I had to create new master-replica instances on PostgreSQL 9.6 to replace old ones with version 9.3 and this way I found there are changes in settings in 9.6 for streaming replication. So here they are:

* wal_level does not have “archive” or “hot_standby” values any more – they are both mapped to new value “replica”