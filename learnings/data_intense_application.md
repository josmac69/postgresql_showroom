# Data intense application with PostgreSQL


* I have heard complains that PostgreSQL is “old crap” because it cannot handle more than several millions records per day.
  Well people this is not truth at all.
* I have worked with application which was able to load and process from 1 000 000 to 3 000 000 records per 5 minutes and even this was not a limit for it!
* Of course this high load of data requires some changes in design and proper HW configuration.
* Here are some basics:

1. You need some ETL process which will load data into database using bulk loads:
   * in case of PostgreSQL use COPY command – it is generally better than pg_bulkload because it does not lock the whole table
   * bulk load will submit all records in one transaction – which mean lower impact on WAL log
   * you can load for example 10 000 or 100 000 records in one COPY command but your ETL must prepare data in “bulletproof” way – in case of some error PostgreSQL will throw away the whole COPY block
   * even if your data are coming as separate records from different users praxis showed that there are always some possibilities how to load them in groups of more records
2. To better organize your data use inheritance – parent-child tables. But be aware of limitations:
   * partitioning by timestamp is the best solution – organize data in some logical groups like 5 minutes, 15 minutes, 1 hour, 1 day…
   * be aware that timezones are real mess in almost every programming language – therefore if you must use different timezones then test, test, test, test….
   * select from parent table locks all child tables with access shared lock – if you need to process data select directly from child table
   * creation of new child table or adding inheritance to it requires exclusive lock on parent – second reason why to avoid selects from parent table
   * child tables will help you to easily manage deletion of old data – you just drop proper child table
3. For high performance needs PostgreSQL proper HW configuration!
   * you need to have dedicated database server – other applications must be on different server and ETL process in best case also
   * if you have only one disk or one disk array for everything then you have no chance to optimize anything and you will never see millions of records processed by PostgreSQL in several minutes…
   * for high load of data and their quick processing you need several disk arrays:
     * very quick RAID 1 or RAID 10 array for WAL log – high quality SSD is the best solution – separation of WAL log requires symbolic link
     * simple but big enough separate RAID 0 array for temporary tablespace – configuration is in postgresql.conf
     * one or more separate RAID 1 or 10 arrays for data / index tablespaces – generally is a good idea to create tables on one array and indexes on another
     * if you process loaded data for reports etc. store those new data in other tablespace on different array – this way processing of data will not slow down new data inserts
   * machine must have enough memory
     * forget to try such a high load on something like 4 cores and 4 GB of memory
     * although in existing versions (12/2015 – pg 9.4) PostgreSQL cannot use properly more than 8GB of shared buffers to share data between connections you still need to have enough memory for all queries running in parallel
     * + memory for autovacuum processes and other pg background processes
4. Also design of the application must be done properly:
   * run as much as possible (depends on CPUs and memory) queries in parallel this way you will better utilize CPUs
