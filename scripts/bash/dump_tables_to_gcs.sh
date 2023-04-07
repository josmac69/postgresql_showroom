#!/usr/bin/env bash

# Bash script – dump tables one by one and upload dumps to Google storage
# Here is one script which some one can find useful.
# We used it when we replaced our old database server with a new machine but wanted
# to be able to access old objects in easy way if we would need to restore / replace anything.
# Scripts dumps one by one existing tables into separate files and stores them compressed on Google storage.
# Has some default parameters but those can be overwritten by sourcing file “.env”
# (which you have to create in the same directory).
# Of course instance where you run program must have active service account which will allow you to write to GS.

# parameter 1 – mask for schemas / tables to process
pgmask=$1
cd “$( dirname “${BASH_SOURCE[0]}”)”
. ./.env
backupdir=${BACKUP_DIR:-/backups}
tempdir=${TEMP_DIR:-/backups}
dbhost=${PG_HOST:-localhost}
dbport=${PG_PORT:-5432}
dbuser=${PG_USER:-youruser}
dbname=${PG_DB:-yourdb}
gsbucket=${GS_BUCKET_PATH:-gs://yourbucket/yourpath}
echo_log () {
echo “$(date +”%Y-%m-%d %H:%M:%S.%N”): $1″
}
pgmaskcond=””
if [ ! -z “${pgmask}” ]; then
pgmaskcond=” AND schemaname||’.’||tablename like ‘${pgmask}’ “
fi
query=”select schemaname||’.’||tablename as tablename from pg_tables where schemaname not like ‘pg%’ and schemaname not like ‘inform%’ ${pgmaskcond} ORDER BY 1″
echo_log “ backup postgresql tables to Google storage one by one “
echo_log “query: ${query}”
for tablename in $(psql -h ${dbhost} -p ${dbport} -U ${dbuser} -d ${dbname} -t -c “${query}”); do
backupfile=”${backupdir}/$(hostname)${tablename}.backup” gsfile=”${gsbucket}/$(hostname)${tablename}.backup”
echo_log “table: ${tablename}”
echo_log “backupfile: ${backupfile}”
echo_log “tempdir: ${tempdir}”
echo_log “gsfile: ${gsfile}”
echo_log “checking GS file…”
gsfilesize=$(gsutil ls -l ${gsfile} 2>/dev/null|head -n1|tr -s ‘ ‘|cut -d’ ‘ -f2)
gsfilesize=${gsfilesize:-0}
if [[ $gsfilesize -eq 0 ]]; then
echo_log “starting dump…”
pg_dump –host=${dbhost} –port=${dbport} –user=${dbuser} –no-password –file=${backupfile} –format=plain –table=${tablename} –verbose –no-tablespaces ${dbname}
if [[ $? -ne 0 ]]; then
echo “$(basename $0): error in dump”
exit 1
fi
echo_log "starting copy to GS..." TMPDIR=${tempdir} gsutil -m cp -Z "${backupfile}" "${gsfile}" if [[ $? -ne 0 ]]; then echo "$(basename $0): error in gsutil" exit 1 fi echo_log "deleting local file ${backupfile}" rm ${backupfile}
else
echo_log “table ${tablename} is already backuped on GS – size: ${gsfilesize}”
fi
done
echo_log “ALL DONE”

# Of course the whole backup can take long time –
# depends on size and number of tables you have.
# Therefore you can run this script several time in parallel for different schema / table mask etc. (see command line parameter).

