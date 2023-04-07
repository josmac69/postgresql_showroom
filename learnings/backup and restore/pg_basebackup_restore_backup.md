# pg_basebackup / pg-barman – restore tar backup

#### Tar backup created by pg_basebackup consists from several files:

* base.tar – directories/ files from main data directory containing pg_clog, pg_xlog directories
* file with WAL logs catched during backup
  * for PG <10 – pg_xlog.tar
  * for PG 10+ – pg_wal.tar
* if you have tablespaces then additional one or several tar files with files from these tablespaces having in its name OID of the tablespace

#### File base.tar contains two special files:

* backup_label
* tablespace_map

backup_label looks like this:
```
START WAL LOCATION: 2423/91000028 (file 000000010000242300000091)
CHECKPOINT LOCATION: 2423/91000060
BACKUP METHOD: streamed
BACKUP FROM: master
START TIME: 201x-xx-xx xx:xx:xx UTC
LABEL: pg_basebackup base backup
```
tablespace_map looks like this:
```
1518653 /mnt/data4/postgresql/9.6
1227964 /mnt/data3/postgresql/9.6
499671 /mnt/data2/postgresql/9.6
16392 /mnt/data1/postgresql/9.6
```

### If you must restore database from pg_basebackup tar files do following:

* Remember – if you are in doubts always search internet for answers never just “presume” or take something for “obvious”… !!!
* If you work remotely ALWAYS use tmux or similar program to preserve sessions !!!
* If you store your pg_basebackup tar files somewhere else it is generally better to copy them to the machine / instance where you will restore database. Of course you need to have enough disk space for it.
* If you work over network take into consideration that just scp of files will take approximately as much time as pg_basebackup needed for making this backup. Because both actions are limited with network bandwidth. Plus untaring files will take fairly long too – depends on CPUs and disk I/O. So do not try to make any too positive time predictions about when database will be up and running.
* To download all files over network just copy them one by one. Running more scp commands in parallel will not help – network bandwidth will be saturated anyway.
* Create small script with lines like “scp remoteuser@xxx.xxx.xxx.xxx:/remote/path/base.tar /local/path” for every file and let it run in separate tmux session – this way you can download them automatically (for example over night) into different places if you need it. Or just “*.tar” into one place of course.
* Find your postgresql main directory – on Debian/ Ubuntu pg config files are usually located in the directory like “/etc/postgresql/x.x/main/” and main directory in “/var/lib/postgresql/x.x/main/”. If you do not know anything about machine search for file postgresql.conf (here you can find the path) or PG_VERSION (located in pg main dir).
* All following steps must be done under postgres user to ensure right ownership and permissions of files !!!
* To be on the safe side archive you current PG main directory (at least without base subdirectory – if you are limited with disk space / time etc.) !!!
* Delete everything in your PG main directory
* untar base.tar file into your PG main directory using command like this (with proper paths of course):
* tar xvf /path/base.tar -C /var/lib/postgresql/x.x/main

If you have tablespaces follow these steps for every tablespace mentioned in “tablespace_map” file:
* take every line (for example “1518653 /mnt/data4/postgresql/9.6”) and do:
```
cd /mnt/data4/postgresql/9.6
rm -rf PG_*
tar xvf /path/1518653.tar -C /mnt/data4/postgresql/9.6
```
notes:
* If you have enough CPUs and tablespaces are  on separate disks / arrays or you use SSDs you can start untar of all files in parallel.
* if you restore to some other machine with different architecture of disks you will have to:
  * either make symlinks to ensure proper paths
  * or fiddle with these paths – but remember you must in such case change content of “tablespace_map” file because PostgreSQL will use these lines to create symlinks to tablespaces in subdirectory pg_tblspc (in PG main dir) !!!

* untar “pg_xlog.tar” (pg_wal.tar) into some other special directory:
```
tar xvg /path/pg_xlog.tar -C /path/archived_wals
tar will unpack WAL logs + subdirectory “archive_status” with files “wal_num”.done
```
* create file “recovery.conf” in PG main directory containing command like this:
```
restore_command = 'cp /path/archived_wals/%f "%p" '
```
* it must contain path to the directory into which you already untar archived WAL logs from pg_xlog.tar file.
* Double check everything especially config files postgresql.conf and pg_hba.conf if you restore on new machine – check if they are part of main directory. If not check directory like /etc/postgresql/xx/main !!!

* Start tailing /var/log/postgresql/postgresql-xx-main.log to see changes

Under some sudoer user start postgresql using:
```
sudo service postgresql start
```
If everything is OK you will see in pg main log lines like these:
```
201x-xx-xx xx:xx:xx.xxx UTC [4520] LOG: restored log file “000000010000028F0000000D” from archive
And if you will see at the end following line then you know you have won:
201x-xx-xx xx:xx:xx.xxx UTC [4520] LOG: database system is ready to accept connections
```

Real cases numbers:

* Parameter / Action	Database 1	Database 2
* PostgreSQL version	10	9.6
* Database size	~220 GB	~3.3 TB
* pg_basebackup runtime	~1:20 hours	~18 hours
* size of catched WAL logs during backup	~1.5 GB	~160 GB
* download of tar files using scp	~2:10 hours	~20:30 hours
* untar of backup files	~1:10 hours	~15:15 hours
* recovery on startup (applying of catched WAL logs)	~2 minutes	~1:30 hours
* total time to start database from backup	~3:30 hours	~38 hours
