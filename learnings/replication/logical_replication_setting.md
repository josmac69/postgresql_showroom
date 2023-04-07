# Setting PostgreSQL logical replication is not entirely straight forward…
Logical replication in PostgreSQL 10 and 11 is amazing but make it working is not entirely straight forward and has some small gotchas. Also you can have specific problems with WAL segments if you publish and subscribe huge amount of the data.

Another specific problem you can encounter is related to WAL segments – logical replication uses WAL segments to ship latest changes done in data. So if you use some cronjob to delete or move outdated WAL segments you have to be very careful – it can break logical replication. All is described below so I recommend to read all this text before you start to fiddle with logical replication.

If you have small database you can use standard simple way “publish all on master and subscribe all on replica”. Here is how to do it:

### on master database:
* create publication using command
```
create publication mypub ...;
```
  * – either for all tables or just publication into which you will add tables one by one
  - if you did not create publication for all tables – add at least one table using command
```
alter publication my_publication add table myschema.mytable;
```

* warning – if you add some already really big table or new partition it will take some time for command to end
  * if command does not want to end in some reasonable time just cancel it and try it later – there can be some pending transactions on that table or there can be autovacuum task currently running on that table – both will prevent to get lock on table for publishing it.

* create logical replication slot using command
```
select pg_create_logical_replication_slot( 'my_logical_slot', 'pgoutput')
```

  * pgoutput is name of plugin used for logical replication

* it is better to create logical replication slot in advance on master because there are cases when attempt to create it from replica as part of “create subscription” command can end with command blocked due to locks
  * you can see existing replication slots in the view pg_replication_slots
  * beside of permanent logical slot you created manually you will sometimes see temporary logical slots with name starting with main logical slot name plus PIDs

* you can check existing replication connections in the view pg_stat_replication
  * the same as above applies here too

### on intended logical replica
* manually create all tables you want to replicate
* create subscription using command
```
CREATE SUBSCRIPTION my_logical_slot CONNECTION 'host=xxx.xxx.xxx.xxx port=5432 password=mysecret user=myuser dbname=mydb' PUBLICATION my_publication WITH (create_slot = false);
```
  * create_slot = false – because you already created logical slot on master
  * Important – I highly recommend to use superusers on both databases to avoid problems with permissions – if you use some limited user you could spend hours after it to fiddle with permissions…
  * the simplest way is to use for the name of the subscription name of logical slot on master database
  * you should see output - CREATE SUBSCRIPTION
  * you can check status of subscription(s) in the view pg_stat_subscription – especially column “last_msg_receipt_time” is interesting for you

* on master db in the postgresql log you should see lines like these:
```
2019-01-15 08:58:06.122 UTC [14370] user@db LOG: starting logical decoding for slot "xxxxx"
2019-01-15 08:58:06.122 UTC [14370] user@db DETAIL:  Streaming transactions committing after 7DF/23632780, reading WAL from 7DE/887F65B0.
2019-01-15 08:58:06.125 UTC [14370] user@db LOG:  logical decoding found consistent point at 7DE/887F65B0
2019-01-15 08:58:06.125 UTC [14370] user@db DETAIL:  Logical decoding will begin using saved snapshot.
2019-01-15 08:58:06.163 UTC [14371] user@db LOG:  logical decoding found initial starting point at 7E3/839CF698
2019-01-15 08:58:06.163 UTC [14371] user@db DETAIL:  Waiting for transactions (approximately 5) older than 958383356 to end.
2019-01-15 08:58:06.197 UTC [14372] user@db LOG:  logical decoding found initial starting point at 7E3/83A1D380
2019-01-15 08:58:06.197 UTC [14372] user@db DETAIL:  Waiting for transactions (approximately 6) older than 958383407 to end.
```

If you see no other errors in both logs then you have to be patient – logical replication will start eventually…
BUT – there is one problem you have to keep in mind if you have big amounts of data. If you publish huge tables PostgreSQL as the first step creates snapshot of current data – see in documentation “Logical replication architecture“. As the first step when you subscribe data on logical replica master transfers this snapshot. And only when snapshot is fully copied master starts to send WAL logs with latest transactions. So make sure if you have some “cleaning cronjob” you will not delete WAL segments prematurely!

If it happens you will have to drop subscription on replica, truncate tables in question on replica, drop publication and logical replication slot on master and start from scratches.

There is another specific problem which can happen – you can see in postgresql log lines like these:
```
2019-01-23 08:17:42.338 UTC [1310] WARNING:  oldest xmin is far in the past 2019-01-23 08:17:42.338 UTC [1310] HINT:  Close open transactions soon to avoid wraparound problems.
```
You might also need to commit or roll back old prepared transactions, or drop stale replication slots.
If this happens unpublish old tables / partitions which cannot be changed any more and refresh subscription on replica. Messages should be gone.

### Another useful notes:
* If you add new tables into publication on master you have to manually refresh subscription on replica using
```
ALTER SUBSCRIPTION xxx REFRESH PUBLICATION;
```
* If you want to drop active subscription you must use this chain of commands:
```
alter subscription xxx disable;
alter subscription xxx set (slot_name=none);
drop subscription xxx;
```

These commands will drop subscription on logical replica. Logical replication slot will still exist on master database
VERY IMPORTANT WARNING !!!! If you drop subscription on replica and keep now unused publication and logical replication slot on master you could in some circumstances have problems with unremoved WAL logs on master. This could eventually fill your disk used for WAL logs and crash you master database. Therefore I strongly recommend to always drop any unused logical replication slot and unused publication on master !

* To see existing subscriptions:
```
select * from pg_subscription;
```
There is one specific “gotcha” you have to keep in mind – if for some reason you decide to unpublish and unsubscribe some tables and later publish as subscribe them again you have to first TRUNCATE tables in question on replica. Otherwise you will end up with all records duplicated!

if you need to change publication on master to publish different operations than previously use alter publication with full list of operations you want to have published:
```
ALTER PUBLICATION xxx SET (publish = ‘insert, update, delete’);
```
