# Streaming replication – increase of max_connections on master can shutdown all your replicas
This is not very pleasant problem. If you must increase “max_connections” on your streaming replication master you will have to make this change before it on all your replicas. Because if you increase “max_connections” on master and keep lower number on replicas then this change will shutdown all your replica databases. It happens because this change is also replicated as it is explained in the second link bellow. And conflict is reported in this case.

If you let replicas running with old setting then after restart of the master all replicas will stop and In postgresql log you will see error like this:
```
2017-11-23 14:48:55.284 UTC [17776] FATAL: hot standby is not possible because max_connections = 1000 is a lower setting than on the master server (its value was 1500)
2017-11-23 14:48:55.284 UTC [17776] CONTEXT: xlog redo XLOG/PARAMETER_CHANGE: max_connections=1500 max_worker_processes=8 max_prepared_xacts=0 max_locks_per_xact=64 wal_level=hot_standby wal_log_hints=off track_commit_timestamp=off
2017-11-23 14:48:57.573 UTC [17771] LOG: startup process (PID 17776) exited with exit code 1
```
* If it happens you just have to make the same change in all config files and restart PostgreSQL on replicas. If you have working recovery scripts then everything will OK again.
* But to increase max_connections is also not entirely easy because there are some limits on Linux. If you try to scale up to several thousands of connections you can get this error and PostgeSQL will not start:
```
2017-11-24 11:03:00.125 UTC [7084] FATAL: could not create semaphores: No space left on device
2017-11-24 11:03:00.125 UTC [7084] DETAIL: Failed system call was semget(5432129, 17, 03600).
2017-11-24 11:03:00.125 UTC [7084] HINT: This error does *not* mean that you have run out of disk space. It occurs when either the system limit for the maximum number of semaphore sets (SEMMNI), or the system wide maximum number of semaphores (SEMMNS), would be exceeded. You need to raise the respective kernel parameter. Alternatively, reduce PostgreSQL's consumption of semaphores by reducing its max_connections parameter.
```
The PostgreSQL documentation contains more information about configuring your system for PostgreSQL.
Then you will have to adjust number of semaphores (SEMMNS) in kernel settings – see links 3, 4 and 5. Using something like this:
```
sudo su
cat /proc/sys/kernel/sem
250 32000 32 128

#new settings
#kernel.sem=<SEMMSL> <SEMMNS>  <SEMMNI>
#kernel.sem=250 256000 32 4096

echo "250 256000 32 4096" > /proc/sys/kernel/sem
echo "kernel.sem = 250 256000 32 4096" >> /etc/sysctl.conf
```
