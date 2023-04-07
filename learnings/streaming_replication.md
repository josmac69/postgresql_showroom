# Streaming replication / pg-barman – archiving WAL logs using script
This option you would need for example when you will implement pg-barman. In such case you will need to archive WAL logs on both local machine and on remote pg-barman machine/ instance.

In such case you can create simple script like this;
```
#!/usr/bin/env bash

fullname=$1
onlyname=$2

homedir=$( dirname "${BASH_SOURCE[0]}")
cd $homedir
. ./pg_archive_wal.env


if [ -z "$LOCAL_ARCHIVE_WAL_DIR" ]; then
        echo "LOCAL_ARCHIVE_WAL_DIR must be specified"
else
        # copy to the local directory
        cp $fullname $LOCAL_ARCHIVE_WAL_DIR/$onlyname
fi


if [ -z "$REMOTE_ARCHIVE_WAL" ]; then
        echo "REMOTE_ARCHIVE_WAL must be specified"
else
        # copy to the remote directory
        scp $fullname $REMOTE_ARCHIVE_WAL/$onlyname
fi
```

This script must be accessible by local postgres user. So the easiest place for it is postgresql main directory like “/var/lib/postgresql/xxx/main”

In script I source variables from other file – pg_archive_wal.env

This file is placed in the same directory together with script. It looks like follows:
```
export LOCAL_ARCHIVE_WAL_DIR=/data/pgarchivedir
export REMOTE_ARCHIVE_WAL=barman@xxx.xxx.xxx.xxx:/var/lib/barman/servername/incoming
```
I chose this solution for more flexibility – if I would need to change target directories then I will just edit this file without necessity to restart postgresql.

To make it working you have to ensure ssh connection from your local postgres user to remote barman user – you must add postgresql public ssh key to authorized_keys under barman.

You must set archive command in local postgresql.conf file like this:
```
archive_command = '/var/lib/postgresql/xxx/main/pg_archive_wal.sh "%p" "%f" >> /var/lib/postgresql/xxx/main/pg_archive_wal.log 2>&1'
```
