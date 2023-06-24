# PostgreSQL monitoring example

## Description
There are currently several PostgreSQL to Prometheus exporters available. I am checking them one by one.

1. **[postgres exporter](https://github.com/prometheus-community/postgres_exporter)**
  * this is an official Prometheus exporter for PostgreSQL server metrics listed in the Prometheus documentation
  * but this exporter depends on the golang pq library - https://github.com/lib/pq - which is currently only in maintenance mode
  * from my own experience I can say tha pq library although the most popular one is not the best one - [library pgx](https://github.com/jackc/pgx) is much quicker in all operations
  * Grafana dashboards for this exporter:
    * [PostgreSQL Exporter Grafana dashboard](https://grafana.com/grafana/dashboards/12485-postgresql-exporter/)
    * [PostgreSQL Exporter Grafana dashboard 2](https://grafana.com/grafana/dashboards/14114-postgres-overview/)

2. **[coroot-pg-agent](https://github.com/coroot/coroot-pg-agent)
  * [blog article about pg-agent](https://coroot.com/blog/pg-agent) - exporter is focusing on query performance metrics
  * [description of metrics](https://coroot.com/docs/metric-exporters/pg-agent/metrics)
  * [another blog article about pg-agent - missing matrics](https://coroot.com/blog/pg-missing-metrics)

3. **[pgmetrics](

4. **[pgscv](

5. **[pg_exporter](

6. **[pg_monz](

7. **[sql_exporter](https://github.com/burningalchemist/sql_exporter)
  * this is a generic SQL exporter which can be used to export metrics from several SQL databases including PostgreSQL
  * it is written in Go and uses the [jackc/pgx](

## Resources
* [How to Benchmark PostgreSQL Using HammerDB Open Source Tool](https://www.enterprisedb.com/blog/how-to-benchmark-postgresql-using-hammerdb-open-source-tool)
*