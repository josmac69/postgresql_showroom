# Problems with autovacuum during high load on server

* In last days we had big spikes in number of inserts on some of our databases causing rapid increase in “database age” (i.e. growth of transaction ID) and some of our databases have reached alerting level of transaction ID value set to 1 billion . See in the left part of this picture
* After huge problems we had with transaction ID wraparound in the past we now als monitor age of database using Telegraf + InfluxDB + Grafana

  * Configuration for telegraf:
```
[[inputs.postgresql_extensible.query]]
     sqlquery="SELECT datname as dbname, age(datfrozenxid) as dbage FROM pg_database ORDER BY 2 DESC;"
     withdbname=false
     tagvalue=""
     measurement="postgresql_dbage"
```

* On databases in question autovacuum was suddenly stacked on processing rapidly growing daily partitions and was unable to re-claim transaction IDs back.

Solution was set using this article – [Tuning Postgres Autovacuum for Scale](https://blog.gojekengineering.com/postgres-autovacuum-tuning-394bb99fe2c0) – we already used bigger memory setting for `autovacuum_work_mem` but kept `autovacuum_vacuum_cost_limit` on default value 200. So now we tested increased values for this parameter and value 2000 currently looks like god setting. As you can see in the right part of the graph autovacuum is now able to keep max transaction ID around 200 000 which is default setting for trigger of autovacuum.

We do not see any significant changes in CPU/ memory usage, disk IO, context switches etc.

Note: configuration can also be tuned using PgTune tool – [PgTune](pgtune.leopard.in.ua/#/)