#!/usr/bin/env bash

# This is simple script which makes backup of PostgreSQL instance
# in tar format and archives tar files on Google storage.
# script makes full backup of postgresql instance using pg_basebackup
# create different env files with variables for script:
#
#env file contains:
# export BACKUP_MAIN_DIR=... - full path to backups main directory
# export BACKUP_GS_PATH=... - bucket and path in Google storage
# export BACKUP_PG_IP=... - IP of postgresql instance to be backuped

envfile=$1

function echo_log {
  echo "$(date +"%Y-%m-%d %H:%M:%S.%N"): $1"
}

[ -z "$envfile" ] && echo "USAGE: ./$(basename $0) env_file" && exit 1

if [ ! -f ${envfile} ]; then
  echo_log "cannot find env file: ${envfile}"
  exit 1
fi

homedir=$( dirname "${BASH_SOURCE[0]}")
cd $homedir
. ./${envfile}

[ -z "$BACKUP_MAIN_DIR" ] && echo "$(basename $0): ERROR: variable BACKUP_MAIN_DIR empty or undefined" && exit 1
[ -z "$BACKUP_GS_PATH" ] && echo "$(basename $0): ERROR: variable BACKUP_GS_PATH empty or undefined" && exit 1
[ -z "$BACKUP_PG_IP" ] && echo "$(basename $0): ERROR: variable BACKUP_PG_IP empty or undefined" && exit 1

backupstamp=$(date +"%Y%m%d%H%M%S")
echo_log "======= pg_basebackup ${BACKUP_PG_IP} - ${backupstamp} ======="
backupmaindir=${BACKUP_MAIN_DIR}
if [ ! -d ${backupmaindir} ]; then
  echo_log "cannot find backup main directory: ${backupmaindir}"
  exit 1
fi
echo_log "backup main dir: ${backupmaindir}"

mkdir -p ${backupmaindir}/${backupstamp}
if [[ $? -ne 0 ]]; then
  echo_log "$(basename $0): cannot create backup directory - ${backupmaindir}/${backupstamp}"
  exit 1
fi

echo_log "backup dir: ${backupmaindir}/${backupstamp}"
pg_basebackup -h ${BACKUP_PG_IP} -D ${backupmaindir}/${backupstamp} -X stream -U barman -P -F t
if [[ $? -ne 0 ]]; then
  echo_log "$(basename $0): error in pg_basebackup"
  exit 1
fi

if [ -d ${backupmaindir}/${backupstamp} ]; then
  for ff in $(ls -Sr ${backupmaindir}/${backupstamp}/*.tar*); do
    f=$(basename ${ff})
    echo_log "copying ${backupmaindir}/${backupstamp}/${f} to ${BACKUP_GS_PATH}/${backupstamp}/${f}"
    gsutil cp ${backupmaindir}/${backupstamp}/${f} ${BACKUP_GS_PATH}/${backupstamp}/${f}
    if [[ $? -ne 0 ]]; then
      echo_log "$(basename $0): error in copy to GS - file: ${ff}"
      exit 1
    fi
  done
else
  echo_log "problem with: ${backupmaindir}/${backupstamp}"
  exit 1
fi

echo_log "deleting backup files on instance..."
for ff in $(ls -Sr ${backupmaindir}/${backupstamp}/*.tar*); do
  rm ${ff}
done

rmdir ${backupmaindir}/${backupstamp}
if [[ $? -ne 0 ]]; then
  echo_log "$(basename $0): cannot remove backup directory - ${backupmaindir}/${backupstamp}"
  exit 1
fi

echo_log "ALL DONE"
