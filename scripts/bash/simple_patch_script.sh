#!/bin/bash

echo ""
echo "Patch for ....."
echo "========================================="

cmdexist=$(command -v psql|wc -l)
if [ $cmdexist == 0 ]; then
    echo "program psql not found"
    exit 1
fi

#if you need to check version of application - do it now
rightver="2.345678"
##I presume you have some table to keep version number...
appver=$(psql -U postgres -d nrs -t -c "select version_number from data.appversion order by appdate desc limit 1")
if [ $? == 0 ]; then
    if [ $(echo "${appver} != ${rightver}"|bc) == 1 ]; then  ##here test for version
        echo "Found version ${appver}"
        echo "This hotfix is intended for version ${rightver}"
        exit 1
    fi
else
    echo "Application not found"
    exit 1
fi

##procedure to implement patch
runpatch() {
dbexist=$(psql -U postgres -d postgres -t -c "select count(*) from pg_database where datname='${dbname}'")
if [ `echo "${dbexist} > 0"|bc` -eq 1 ]; then
    echo "Implementing hotfix on database $dbname..."
    psql -U postgres -d ${dbname} -f patch_${dbname}.sql   ##check your file name
    if [ $? != 0 ]; then
        echo "Error in patch on database $dbname"
        exit 1
    fi
    echo "$dbname DONE"
    echo ""
fi
}

##here you can have more of these calls for different dbs or cycle
dbname=mydatabase
runpatch

echo ""
echo "All DONE"
echo ""
