# Monitoring waits on database

If your database has some problems with locks you can try to monitor them with this very simple bash script:
```
#!/bin/bash

while true;
do
l=$(ps -ef|grep wait|grep -v grep|wc -l)

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

if [ $l != 0 ]; then
psql -U postgres -c " select * from pg_locks ;" >> ${TIMESTAMP}
psql -U postgres -c " select * from pg_stat_activity order by state;">>${TIMESTAMP}
fi
sleep 1
done
```

If some waiting process is found in process list then content on pg_locks and pg_stat_activity is saved into file with timestamp in name.
Scripts checks processes every 1 second. You can use longer pause between checks. Smaller pause does not have any practical sense.
Short locks happen sometimes but we do not need to worry about them.
Script is so simplistic because of speed. Feel free to modify it any way you want…