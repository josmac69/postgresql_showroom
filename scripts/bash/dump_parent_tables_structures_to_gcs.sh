#!/usr/bin/env bash

# Bash script – dump structures of parent tables one by one and upload them to Google storage
# Similar to previous script for dump of tables and dump of functions. This one is useful if you use a lot of parent-child tables. Script finds all parent tables, dumps their structures each one into separate dump file and upload them to Google storage.

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
query=”select schemaname||’.’||relname from pg_stat_all_tables where relid in (select DISTINCT inhparent from pg_inherits) order by 1″
echo_log “ backup postgresql parent tables structures to Google storage one by one “
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
pg_dump –host=${dbhost} –port=${dbport} –user=${dbuser} –no-password –file=${backupfile} –format=plain –table=${tablename} –verbose –no-tablespaces ${dbname} –schema-only
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
