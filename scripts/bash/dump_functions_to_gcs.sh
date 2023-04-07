#!/usr/bin/env bash

# Bash script – dump functions one by one and upload them to Google storage
# Script is similar to previous script for dump of tables one by one. Difference is mainly in SQL part.

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
pgmaskcond=” AND ns.nspname||’.’||p.proname like ‘${pgmask}’ “
fi
query=”select ns.nspname||’.’||p.proname from pg_proc p join pg_namespace ns on p.pronamespace = ns.oid where ns.nspname not like ‘pg%’ and ns.nspname not like ‘inform%’ ${pgmaskcond} ORDER BY 1″
query=”select p.oid||’:’||ns.nspname||’.’||p.proname||'(‘||substr(pg_get_function_arguments(p.oid),1,40)||’)’ from pg_proc p join pg_namespace ns on p.pronamespace = ns.oid where ns.nspname not like ‘pg%’ and ns.nspname not like ‘inform%’ ${pgmaskcond} ORDER BY 1″
echo_log “ backup postgresql functions to Google storage one by one “
echo_log “query: ${query}”
IFS=$’\n’
for funcstr in $(psql -h ${dbhost} -p ${dbport} -U ${dbuser} -d ${dbname} -t -c “${query}”); do
funcoid=$(echo “${funcstr}”|cut -d’:’ -f1)
funcname=$(echo “${funcstr}”|cut -d’:’ -f2|sed ‘s/ //g; s/[]//g; s/\”//g’)
backupfile=”${backupdir}/$(hostname)${funcname}.backup” gsfile=”${gsbucket}/$(hostname)${funcname}.backup”
echo_log “funcstr: ${funcstr}”
echo_log “function oid: ${funcoid}”
echo_log “function: ${funcname}”
echo_log “backupfile: ${backupfile}”
echo_log “tempdir: ${tempdir}”
echo_log “gsfile: ${gsfile}”
echo_log “checking GS file…”
gsfilesize=$(gsutil ls -l ${gsfile} 2>/dev/null|head -n1|tr -s ‘ ‘|cut -d’ ‘ -f2)
gsfilesize=${gsfilesize:-0}
if [[ $gsfilesize -eq 0 ]]; then
echo_log “starting dump…”
psql -h ${dbhost} -p ${dbport} -U ${dbuser} -d ${dbname} -t -c “SELECT pg_get_functiondef(${funcoid})” > ${backupfile}
if [[ $? -ne 0 ]]; then
echo “$(basename $0): error in source code dump”
exit 1
fi
echo_log "starting copy to GS..." TMPDIR=${tempdir} gsutil -m cp -Z "${backupfile}" "${gsfile}" if [[ $? -ne 0 ]]; then echo "$(basename $0): error in gsutil" exit 1 fi echo_log "deleting local file ${backupfile}" rm ${backupfile}
else
echo_log “function ${funcname} is already backuped on GS – size: ${gsfilesize}”
fi
done
echo_log “ALL DONE”

