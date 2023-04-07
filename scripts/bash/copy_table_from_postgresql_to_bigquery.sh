#!/usr/bin/env bash

# Bash script – sync table from PostgreSQL to Bigquery
# We switched to the golang solution but maybe this bash script can be useful for some one.
# Works for any table. Changes PostgreSQL types to Bigquery types.
# Exports into JSON format and copies it to Google Storage.
# Uses Google command line tools.
# ENV variables are stored in the same directory in the file .env must be sourced before starting script.
# Needs command line parameters:
#  1. postgresql schema.tablename,
#  2. bigquery dataset.tablename (not necessary if you want to have it in the same schema with the same name as on postgresql.

# Note: script export postgresql system column xmin (transaction ID for given row) to Bigquery: xmin::text::bigint as pgtransactionid
# This is our solution to be able check later if there were some changes in PostgreSQL table and therefore we must reimport it to Bigquery.
# We use this because our PostgreSQL database is master and we use Bigquery only as copy for really heavy aggregations.

# always imports table from PG into BQ - even empty table - in some cases we need them with proper structure

# USAGE: parameter "pg_schemaname.pg_tablename"
#
# exports in JSON format, CSV was found as being very limited
# needs env vars:
#   BQ_EXPORT_DIR - where export file will be stored - if missing /tmp is used

debug=${CWDEBUG:-0}

tablename=$1
bqtarget=$2

[[ "$#" -lt 1 ]] && echo "USAGE: $0 pg_schemaname.pg_tablename [bq_target_dataset.bq_target_tablename]" && exit 1

[[ "$tablename" != *"."* ]] && echo "$(basename $0): tablename must be in format schema.table (value: $tablename)" && exit 1
[[ -z "${QUERIES_USER+x}" ]] && echo "$(basename $0): ERROR: variable QUERIES_USER not set" && exit 1
[[ -z "${QUERIES_DB+x}" ]] && echo "$(basename $0): ERROR: variable QUERIES_DB not set" && exit 1
[[ -z "${QUERIES_HOST+x}" ]] && echo "$(basename $0): ERROR: variable QUERIES_HOST not set" && exit 1
[[ -z "${QUERIES_PORT+x}" ]] && echo "$(basename $0): ERROR: variable QUERIES_PORT not set" && exit 1

schemapart=$(echo "$tablename"|sed 's/ //g'|cut -d'.' -f1)
tablepart=$(echo "$tablename"|sed 's/ //g'|sed 's/\"//g'|cut -d'.' -f2)
tablename=$(echo "${schemapart}.\"${tablepart}\"")
[ "$debug" == "1" ] && echo "bqtarget: ${bqtarget}"
[ "$debug" == "1" ] && echo "tablename: ${tablename}"

bqtablename=${bqtarget:-$(echo $tablename|sed 's/\"//g')}
[ "$debug" == "1" ] && echo "BQ import table: ${bqtablename}"

exportfolder=${BQ_EXPORT_DIR:-"/tmp"}
[ "$debug" == "1" ] && echo "exportfolder: ${exportfolder}"

# check if table exists
exists=$(psql -U ${QUERIES_USER} -d ${QUERIES_DB} -h ${QUERIES_HOST} -p ${QUERIES_PORT} -t -c "select count(*) from information_schema.tables where table_schema||'.\"'||table_name||'\"'='${tablename}'")
[ "$debug" == "1" ] && echo "check if table exists in PostgreSQL: ${exists}"

if [[ $exists -eq 0 ]]; then
  echo "table ${tablename} not found"
  exit 1
fi

tablenameforfiles=$(echo "${tablename}"|sed 's/"//g')
[ "$debug" == "1" ] && echo "tablenameforfiles: ${tablenameforfiles}"

schemafilepath="${exportfolder}/schema.${tablenameforfiles}.json"
[ "$debug" == "1" ] && echo "schemafilepath: ${schemafilepath}"

# remove old schema file
rm ${schemafilepath} -f

##### export structure into json
# this query does not consider 'repeated' columns - they do not work well with present BQ
psql -U ${QUERIES_USER} -d ${QUERIES_DB} -h ${QUERIES_HOST} -p ${QUERIES_PORT} -t -c "select '['||string_agg(row_to_json(a.*)::text,',')||']' from ( select name, type, mode from (select 'pgtransactionid' as name, 'integer' as type, 'nullable' as mode, 0 as ordinal_position union all select replace(column_name,'.','_') as name, case when lower(data_type)='user-defined' then 'string' when udt_name like '%int%' then 'integer' when udt_name like '%text%' or udt_name like '%varchar%' then 'string' when udt_name like '%bool%' then 'boolean' when udt_name like '%float%' or udt_name like '%numeric%' then 'float' when udt_name like '%timestamp%' then 'timestamp' else 'string' end as type, case when lower(data_type) like '%array%' then 'repeated' when is_nullable='NO' then 'nullable' else 'nullable' end as mode, ordinal_position from information_schema.columns where table_schema||'.\"'||table_name||'\"'='${tablename}') b order by ordinal_position ) a "> ${schemafilepath}
if [[ $? -ne 0 ]]; then
  echo "$(basename $0): error in structure query"
  exit 1
fi

# export data in json - timestamps must be in UTC
exportfile="${tablenameforfiles}.csv"
[ "$debug" == "1" ] && echo "exportfile: ${exportfile}"

exportfilepath="${exportfolder}/${exportfile}"
[ "$debug" == "1" ] && echo "exportfilepath: ${exportfilepath}"

# remove old files
rm ${exportfilepath} -f

##### export query - solves some known issues with format of data
#boolean - bigquery requires text or integer
query=$(psql -U ${QUERIES_USER} -d ${QUERIES_DB} -h ${QUERIES_HOST} -p ${QUERIES_PORT} -t -c "select 'select '||string_agg(col,',')||' from only ${tablename}' from (select col from ( select 'xmin::text::bigint as pgtransactionid' as col, 0 as ordinal_position union all select case when (udt_name like '%text%' or udt_name like '%varchar%' or lower(data_type) like '%character%' or lower(data_type) like '%json%' ) then 'replace(replace(\"'||column_name||'\"::text, chr(10),''''), chr(13),'''')' else '\"'||column_name||'\"' end||'::'||case when lower(data_type) like '%user%defined%' or lower(data_type) like '%json%' or lower(data_type) like '%character%' then 'text' when lower(data_type) like '%boolean%' then 'text' else replace(data_type, 'with time', 'without time') end||' as \"'||replace(column_name,'.','_')||'\"'::text as col, ordinal_position::int as ordinal_position from information_schema.columns where table_schema||'.\"'||table_name||'\"'='${tablename}') b order by ordinal_position) a")

[ "$debug" == "1" ] && echo "query: $query"

# export using psql
[ "$debug" == "1" ] && echo "exporting ${tablename} from PostgreSQL"
psql -U ${QUERIES_USER} -d ${QUERIES_DB} -h ${QUERIES_HOST} -p ${QUERIES_PORT} -t -c "COPY (select * from ( ${query} ) t)  TO STDOUT CSV DELIMITER ',' FORCE QUOTE * ;"|sed 's/\\\\//g' > ${exportfilepath}
if [[ $? -ne 0 ]]; then
  echo "$(basename $0): ERROR in json export"
  exit 1
fi

if [ ! -f ${exportfilepath} ]; then
  echo "$(basename $0): export file ${exportfilepath} does not exist, terminating"
  exit 1
fi

[ "$debug" == "1" ] && echo "copying ${tablename} to GS"
gsutil -q -o GSUtil:parallel_composite_upload_threshold=10M cp ${exportfilepath} gs://your_bucket/${exportfile}
if [[ $? -ne 0 ]]; then
  echo "$(basename $0): error in parallel upload to gs"
  exit 1
fi

# create table on BQ with proper structure
[ "$debug" == "1" ] && echo "deleting BQ ${bqtablename}"
bq rm -f -t ${bqtablename}
if [[ $? -ne 0 ]]; then
  echo "$(basename $0): error in bq table remove"
  exit 1
fi

[ "$debug" == "1" ] && echo "creating BQ ${bqtablename}"
bq mk --quiet --schema=${schemafilepath} ${bqtablename} 1>/dev/null
if [[ $? -ne 0 ]]; then
  echo "$(basename $0): error in bq table creation"
  exit 1
fi

[ "$debug" == "1" ] && echo "importing BQ ${bqtablename}"
# bq cannot use schema file stored on google
bq load -q --source_format=CSV --schema=${schemafilepath} ${bqtablename} gs://your_bucket/${exportfile}
if [[ $? -ne 0 ]]; then
  echo "$(basename $0): BQ ${bqtablename} load ERROR"
  exit 1
fi

echo "$(basename $0): BQ ${tablename} load OK"

#delete files
rm ${exportfilepath} -f
rm ${schemafilepath} -f

[ "$debug" == "1" ] && echo "bq_import_pg_table.sh DONE"

exit 0
