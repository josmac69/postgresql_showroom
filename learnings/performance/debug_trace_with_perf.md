# Debug / trace PostgreSQL with perf
* Read this text [Tracing PostgreSQL with perf](https://www.2ndquadrant.com/en/blog/tracing-postgresql-perf/).
* Or this [perf CPU sampling](https://brendangregg.com/blog/2014-06-22/perf-cpu-sample.html). This text contains short summary.

Install perf:
```
sudo apt-get install linux-tools-3.16
```
(or other version – depends on your OS)

Install postgresql server debug symbols:
```
sudo apt-get install postgresql-9.6-dbg
```
(or other version based on your PG)

check postgres processes:
```
sudo perf top -u postgres
```
