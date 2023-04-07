#!/usr/bin/env bash

# Bash script – synchronize daily partitions between 2 postgresql servers
# This bash script worked well for a very long time so maybe it can be useful also for someone else.
# Use case – synchronizes both partitioned and unpartitioned tables between source and archive database once per day.
# List of tables is in env variables stored in .env file. Tasks run in parallel.

debug=${DBADEBUG:-0}

vmaxjobs=8

echo_log () {
  echo "$(date +"%Y-%m-%d %H:%M:%S.%N"): $1"
}

function psqlsource() {
  psql -U $SOURCE_USER -h $SOURCE_HOST -p $SOURCE_PORT -d $SOURCE_DB -t -c "$1"
  [ $? -ne 0 ] && echo_log "ERROR in psqltosource - query: $1" && exit 1
}

function checkjobs {
  [ "$debug" == "1" ] && echo_log "checkjobs jobsarray dim: ${!jobsarray[@]}"
  [ "$debug" == "1" ] && echo_log "checkjobs jobsarray elements: ${jobsarray[@]}"
  for j in "${!jobsarray[@]}"; do
    [ "$debug" == "1" ] && echo_log "checking job: ${jobsarray[$j]}"
    wait ${jobsarray[$j]}
    rc=$?
    [ "$debug" == "1" ] && echo_log "job ${jobsarray[$j]} exit code: $rc"
    if [[ $rc -ne 0 ]] && [[ $rc -ne 127 ]]; then
      echo_log "$(basename $0): ERROR in job ${jobsarray[$j]} exit code $rc"
      exit 1
    fi
    [ "$debug" == "1" ] && echo_log "job ${jobsarray[$j]} OK"
    unset jobsarray[$j]
  done
}

function maxjobs {
  [ "$debug" == "1" ] && echo_log "maxjobs: ${#jobsarray[@]}"
  [ "$debug" == "1" ] && echo_log "maxjobs jobsarray dim: ${!jobsarray[@]}"
  [ "$debug" == "1" ] && echo_log "maxjobs jobsarray elements: ${jobsarray[@]}"
  if [[ ${#jobsarray[@]} -ge $vmaxjobs ]]; then
    checkjobs
  fi
}

echo_log "=== COPYING DAILY PARTITIONS ==="

scriptdir=$( dirname "${BASH_SOURCE[0]}")
cd $scriptdir
. .env

queryunpartitioned=""
queryparents=""
[ "$debug" == "1" ] && echo_log "UNPARTITIONED_TABLES_TO_COPY: $UNPARTITIONED_TABLES_TO_COPY"
if [ "$UNPARTITIONED_TABLES_TO_COPY" != "" ]; then
  queryunpartitioned="union all select relnamespace::regnamespace::text||'.'||relname from pg_class where relname in ($(echo "'$UNPARTITIONED_TABLES_TO_COPY'"|sed "s/,/','/g"))"
fi
[ "$debug" == "1" ] && echo_log "queryunpartitioned: $queryunpartitioned"

[ "$debug" == "1" ] && echo_log "PARTITIONED_TABLES_TO_COPY: $PARTITIONED_TABLES_TO_COPY"
if [ "$PARTITIONED_TABLES_TO_COPY" != "" ]; then
  queryparents="and p.relname in ($(echo "'$PARTITIONED_TABLES_TO_COPY'"|sed "s/,/','/g"))"
fi
[ "$debug" == "1" ] && echo_log "queryparents: $queryparents"

sourcequery="select * from (with dates as (select to_char(clock_timestamp(),'YYYYMMDD') as _today, to_char(clock_timestamp()+interval'1day','YYYYMMDD') as _tomorrow), children as (select c.relnamespace::regnamespace::text||'.'||c.relname as childtablename from pg_inherits i join pg_class c on i.inhrelid=c.oid join pg_class p on i.inhparent=p.oid where c.relname not like '%unknowns%' $queryparents ) select childtablename from children, dates where childtablename not like '%'||_today::text||'%' and childtablename not like '%'||_tomorrow::text||'%' $queryunpartitioned ) a order by 1"
[ "$debug" == "1" ] && echo_log "sourcequery: $sourcequery"

for table in $(psqlsource "$sourcequery"); do
  maxjobs
  $scriptdir/table_pg2pg.sh $table &
  jobsarray=("${jobsarray[@]}" $!)
done

echo_log "=== END ==="
