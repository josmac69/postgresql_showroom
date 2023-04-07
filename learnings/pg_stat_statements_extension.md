# Better query statistics with extension pg_stat_statements
Installation:

if missing then install “postgresql-contrib” package of proper version
add into postgresql.conf:

```
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all
```

restart postgresql service (extension must allocate some memory)
create extension: create extension pg_stat_statements;

Shows queries on all databases. This extension is very useful when you need to analyze which queries are processed by your server. For example when you need to analyze what is going on when you use plproxy etc. this extension will greatly help you.

If queries are not too long you can join it with pg_stat_activity using column “query” as join key and get also PIDs of processes and other details.

