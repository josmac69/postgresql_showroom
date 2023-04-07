# Transaction ID wraparound error
* Up until a few weeks ago I thought I will never see transaction ID wraparound error on some of my databases.
* Not that I would miss it but it felt like something with very very low possibility of occurrence.

Well, not any more…
* We implemented logical replication between our production database collecting data from web widgets and our data warehouse databases.
* Previously we transferred data once per day using dump and restore but lately this took several hours to finish even with parallel run of tasks.
* Collecting database has huge amount of small transactions – every event from every widget is collected and in most cases inserted in separate transaction – in current version grouping would be problematic. On collecting database we have ~150 – ~400 millions of inserts each day.
* Logical replication moved the same amount of transaction on data warehouse database. And although we have quite detailed database monitoring on all instances it turned out it was not good enough.

* Our problem was not entirely small, collecting database collects 30 – 50 GB daily and main data warehouse db had at the time of problem ~22 TB of data for last 5 years in ~40 000 “our” tables which meant ~80 000 tables total (including toast tables etc.)

* Autovacuum fell behind and after several days of supposedly non problematic run we ended up with transaction ID wraparound error on data warehouse database. Problem of course occurred during the night and in the morning we already had database blocked by this error. * Database refused to process any commands except of selects with error message:
```
ERROR: database is not accepting commands to avoid wraparound data loss in database “xxxxx”
HINT: Stop the postmaster and vacuum that database in single-user mode.
You might also need to commit or roll back old prepared transactions, or drop stale replication slots.
```
* As first step I did quick research on internet and since there is obviously no quick and easy solution for this problem, especially with number of tables so big.
* I started immediately with preparation of new data warehouse database. Because we run some daily aggregations there for clients dashboards etc.
  * These aggregations must create new daily data – which was suddenly not possible on database blocked by wraparound.
  * So after several hours new data warehouse database with data for last 7 days was able to host all essential daily tasks and I could concentrate on wraparound error.

* I tried what documentation and everyone on web recommends:
  * Started database in single user mode and started VACUUM. For the record to start in single user mode do:
```
sudo service postgresql stop
sudo su postgres
/usr/lib/postgresql/xx/bin/postgres –single -D /var/lib/postgresql/xx/main -c config_file=/etc/postgresql/xx/main/postgresql.conf -E -j dbname
```

* But progress of this command was so incredibly low that simple mathematics gave me estimate of more than one week of vacuuming in single user mode – i.e. database would be totally inaccessible. Which was pure nonsense.

Therefore I:

* canceled single user mode
* upgraded instance to more CPUs and memory
* reconfigured memory settings to have more memory for maintenance and vacuum
* started postgresql in normal mode
* prepared some scripts and started several parallel VACUUM FREEZE processes each on different range of tables
* started copying of data from blocked database into new data warehouse db – once daily data are collected they are not touched later so I could be sure there were no problems with transactions on older partitions.

Of course not all things were easy. For example start of PostgreSQL into normal mode did not work in first attempt. Log gave me errors:
```
2019-03-25 10:35:30.854 UTC [27323] LOG: invalid primary checkpoint record
2019-03-25 10:35:30.854 UTC [27323] LOG: invalid secondary checkpoint record
2019-03-25 10:35:30.854 UTC [27323] PANIC: could not locate a valid checkpoint record
2019-03-25 10:35:31.402 UTC [27320] LOG: startup process (PID 27323) was terminated by signal 6: Aborted
2019-03-25 10:35:31.402 UTC [27320] LOG: aborting startup due to startup process failure
2019-03-25 10:35:31.416 UTC [27320] LOG: database system is shut down
```

As I already mentioned before – transactions on older partitions are very rare and data for last 7 days are available on collecting database. Therefore I decided to use commands described in “postgresql error PANIC: could not locate a valid checkpoint record” question on stackoverflow.
```
pg_resetwal /var/lib/postgresql/xx/main
# showed error message, therefore I forced reset
pg_resetwal -f /var/lib/postgresql/xx/main
```
With parallel run of scripts took freeze of the whole database ~4 days and database was accessible for selects and during that time I also copied necessary data into new db.

Of course I immediately implemented better monitoring using telegraf and influxDB and queries from this text – Implement an Early Warning System for Transaction ID Wraparound in Amazon RDS for PostgreSQL

How does it look like in telegraf configuration:
```
[[inputs.postgresql_extensible.query]]
sqlquery=”SELECT datname as dbname, age(datfrozenxid) as dbage FROM pg_database ORDER BY 2 DESC;”
withdbname=false
tagvalue=”db”
measurement=”postgresql_dbage”
```
And adequate dashboard and alerts in Grafana.