# Native partitioning – how to check partitions and manipulate with them

* How to check if table is partition or to find existing partitions – there is a new column “relispartition” in pg_class table:
```
select * from pg_class where relispartition is true
```
* Table “pg_class” contains also new column “relpartbound” which according to documentation contains “internal representation of the partition bound”. So something like this:
```
{PARTITIONBOUND :strategy r :listdatums <> :lowerdatums ({PARTRANGEDATUM :infinite false :value {CONST :consttype 1114 :consttypmod -1 :constcollid 0 :constlen 8 :constbyval true :constisnull false :location 78 :constvalue 8 [ 0 -128 -47 -60 -74 -12 1 0 ]}}) :upperdatums ({PARTRANGEDATUM :infinite false :value {CONST :consttype 1114 :consttypmod -1 :constcollid 0 :constlen 8 :constbyval true :constisnull false :location 105 :constvalue 8 [ -1 -33 -88 -30 -54 -12 1 0 ]}})}
```
* Manipulation with partitions – table (with proper structure of course) can be attached to the parent table using:
```
ALTER TABLE parent_table ATTACH PARTITION partition_table FOR VALUES boundaries
```
* The same way you can detach partition:
```
ALTER TABLE parent_table DETACH PARTITION partition_table
```

* indexes must be created separately on every partition
  * every partition can have different indexes
  * if you already have indexes on parent table, when you create partition, indexes are created automatically
* Parameter “constraint_exclusion” changes behavior of query planner. Values “on”, “off”, “partition” (default)
* There is the new object in system catalog “pg_partitioned_table” which contains basic information about parent table. Simple query to get basic info:
```
select par.relnamespace::regnamespace::text as parent_schema, par.relname as parent_tablename, case partstrat when 'l' then 'list' when 'r' then 'range' end as partition_strategy, partnatts as columns_partkey from pg_partitioned_table pt join pg_class par on pt.partrelid=par.oids
```

