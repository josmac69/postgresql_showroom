#!/bin/bash

#source machine
hostsource=127.0.0.1  ##localhost or different machine
dbsource=mysourcedb  ##name of source database
schemasource=mysourceschema  ##name of source schema

#target machine
hosttarget=172.xxx.xxx.xxx  ##your target host IP
dbtarget=mytargetdb
schematarget=othermyschema

#list of tables - here write list of tables delimitted with space
tables="table1 table2 table3"

#or create list of tables using query into db
tables=$(psql -U postgres -t -c "select table_name from information_schema.tables   where table_schema='${schemasource}' and table_name like '...here_some_mask...' ")

##--------------------------------------------------------------------------------

for t in $tables; do
echo "checking table ${t}"

tablenamesource=$schemasource.$t
tablenametarget=$schematarget.$t

echo "coping table $tablenamesource"

#first copy structure
pg_dump -U postgres -F plain -n $schemasource -t $tablenamesource -h $hostsource -s $dbsource | psql -U postgres -d $dbtarget -n $schematarget -h $hosttarget

#second - copy data
echo "coping data..."
psql -U postgres -h ${hostsource} -d ${dbsource} -c "copy ${tablenamesource} to stdout " | psql -U postgres -h ${hosttarget} -d ${dbtarget} -c "copy ${tablenametarget} from stdin"

done
