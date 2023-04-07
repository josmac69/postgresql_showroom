# PostgreSQL performance tricks

### Do not use SELECT DISTINCT – use GROUP BY
From my experiences with PG 8.4 and PG 9.3 I can say that this is true. So far GROUP BY was always quicker or even much more quick.
```
select distinct column from table
select column from table group by column
```

### use LATERAL only on small amount of data
PostgreSQL 9.3 introduced new type of join – LATERAL. You can join with other table and make pre-select from joined table using some value from other table.
It is great but if you have a big amount of data then this nice feature can kill performance. Use it in such a case only when your query is so complicated that you cannot find any other way arround…