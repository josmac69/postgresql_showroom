# Tests of cstore_fdw extension

Overview:

* cstore_fdw is very promising columnar storage extension for PostgreSQL – home page: [https://www.citusdata.com/community/cstore-fdw](https://web.archive.org/web/20210919025707/https://www.citusdata.com/community/cstore-fdw)
* it compress data and repeated values in column
* works as foreign data wrapper
* I tested on PostgreSQL 9.3 on which my app presently runs
* I tested speed and data file size

Results:

* cstore_fdw saved from 50% to 85% percent of the disk space
* analytical queries were running 3x or 4x quicker on cstore_fdw foreign tables then on original normal PostgreSQL tables
* cstore_fdw definitely saves both disk space and run time of analytical queries
* but if you need inheritance (which is my case) you must wait for production version of Pg 9.5 + new version of cstore_fdw (existing 1.3 does not support pg 9.5)
