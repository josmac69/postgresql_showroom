# PostgreSQL on Google Cloud SQL


Pros:

1. Creation of new PostgreSQL instance is absolutely easy – does not require any DBA experiences
2. Instance uses SSD disk by default so data access is very quick. Note – When setting initial disk size take into consideration only PG data. You do not need to worry about space for OS.
3. All necessary things (creation of users, creation of databases…) are managed from Google cloud console web GUI – so it is very easy – no DBA experiences necessary. The same actions can also be done using command line tool from Google (gcloud sql).
4. You can easily load data using psql or pg_restore from some other instance (you just need to authorize IP or allow general access from all IPs)
5. You can in absolutely easy way create read replicas for main instance.
6. Backups are done automatically.
7. SSD disk will be extended automatically as your data grow.

Cons:

1. You do not have SUPERUSER rights on any user. Although you get “postgres” user it is not superuser. So you cannot make system wide changes using “alter system” and similar actions.
2. You cannot influence majority of PostgreSQL settings – for example global setting of “work_mem” or “shared_buffers” (my testing Cloud SQL instance used 2.4 GB shared_buffers for database with 3.5 GB data).
   * But you can still set “work_mem” for database or session.
   * In GUI you can set (as so called “database flags”) only following settings – autovacuum, autovacuum_analyze_scale_factor, autovacuum_analyze_threshold, autovacuum_naptime, autovacuum_vacuum_scale_factor, autovacuum_vacuum_threshold, default_statistics_target, log_autovacuum_min_duration, temp_file_limit – ([https://cloud.google.com/sql/docs/postgres/flags](https://web.archive.org/web/20210728185928/https://cloud.google.com/sql/docs/postgres/flags))
3. Google requires that you set “maintenance window” for implementation of upgrades. In [Cloud SQL for PostgreSQL FAQ](https://web.archive.org/web/20210728185928/https://cloud.google.com/sql/docs/postgres/faq) you can see in question [“What kind of maintenance shutdowns should I expect with my instance?”](https://web.archive.org/web/20210728185928/https://cloud.google.com/sql/docs/postgres/faq#maintenancerestart) this statement “We recommend that you design your applications to deal with situations when your instance is not accessible for short periods of time, such as in a maintenance shutdown.”
   We checked with Google support and maintenance window really causes restarts without any HA option.
4. Read replicas have from our perspective even bigger problem with “maintenance window” because you cannot set it specifically. So replicas can be technically restarted “any time”…
5. To be fair – Google assures that these restarts are very rare – once per several months…
6. Currently Cloud SQL supports only PostgreSQL 9.6 which is from our perspective big minus because version 10 (already in 10.4 subversion) proofed to be much better and quicker.
7. SSD disk used for instance can only grow. You cannot shrink it if you delete some data and do not need so big disk any more.

Resume:

* If you want to use PostgreSQL database without any worries and maintenance from your side and restarts for maintenance are not problem for you then YES – PostgreSQL Cloud SQL database is a great option for you.
* Restarts during maintenance window can be a big problem for systems requiring 100% availability of the database – but these systems should anyway use fall back databases. So if you set more PostgreSQL Cloud SQL instances you will be happy with this service too.
