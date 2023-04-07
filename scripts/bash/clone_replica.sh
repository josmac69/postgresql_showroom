#!/usr/bin/env bash

# Bash script – clone PostgreSQL replica
# This script helps you create new PostgreSQL replica by cloning existing one.
# You have to prepare your new machine/ instance with as much the same environment as possible to your previous one.
# You definitely need the same main version of PostgreSQL and preferably also the same minor version as on master.
# Or if you cannot install the same minor version then higher minor version is OK. But not lower minor version then on master!!!
# You will have to manually copy postgresql.conf and pg_hba.conf file or manually adjust them – depends on your environment.
# But to start replication “hot_standby” must be set to ON.
# Script must run under root user.
# pg_basebackup requires .pgpass file with password in postgres home dir – usually /var/lib/postgresql
# If you use tablespaces you need to adjust proper paths/ directories/ disk on new replica too – pg_basebackup makes really exact copy of files including all paths.
# Script presumes standard PostgreSQL paths + PG version 9.5 – change these paths for your instalation.
#You need to configure ssh under postgres on your new intended replica to postgres on your cloning replica.
#It presumes your “recovery.conf” file is placed in standard PostgreSQL main directory so it can start recovery

function echo_log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S.%N"): $1"
}

curdate=$(date +%Y%m%d%H%M)

if [ "$EUID" -ne 0 ]; then
  echo_log "Please run this script as root"
  exit 1
fi

echo_log "checking postgresql status..."
stillrunning=$(ps -ef|grep /usr/lib/postgresql/9.5/bin/postgres|grep -v grep|wc -l)

if [ $stillrunning -gt 0 ]; then
  echo_log "stopping local PostgreSQL"
  su -c "/usr/lib/postgresql/9.5/bin/pg_ctl stop -D /var/lib/postgresql/9.5/main" postgres
  if [ $? -ne 0 ]; then
    echo_log "$(basename $0): ERROR: cannot run pg_ctl stop"
    exit 1
  fi
fi

echo_log "checking postgresql status..."
stillrunning=$(ps -ef|grep /usr/lib/postgresql/9.5/bin/postgres|grep -v grep|wc -l)

if [ $stillrunning -gt 0 ]; then
  echo_log "ERROR: postgresql did not stop..."
  exit 1
fi

echo_log "removing old postgresql data files..."
rm /var/lib/postgresql/9.5/main/* -rf
if [ $? -ne 0 ]; then
  echo_log "$(basename $0): ERROR: cannot delete old local postgresql&nbsp; data files - main directory"
  exit 1
fi

echo_log "taking base backup"
su -c "pg_basebackup -h xxx.xxx.xxx.xxx -D /var/lib/postgresql/9.5/main/ -U your_pg_user -P --xlog-method=stream" postgres
if [ $? -ne 0 ]; then
  echo_log "$(basename $0): ERROR: cannot make base backup"
  exit 1
fi

echo_log "starting local postgresql"
service postgresql start
