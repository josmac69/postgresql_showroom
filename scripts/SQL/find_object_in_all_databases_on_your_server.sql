/*
Simple query to find object in all databases on your server
This is also only very small hint.

As you probably already very well know databases on PostgreSQL server are isolated and you cannot so easily run queries across them.

This small query shows one simple way how to check for some pattern in table and view names across all databases.
*/

WITH pattern AS
(
	SELECT  '...here_your_pattern_even_with_%_character....'::text AS _mask
) --add %
WHERE you need it - start / end / inside etc..., dbs AS (
SELECT  datname
       ,'dbname='||datname AS _link
FROM pg_database
WHERE datistemplate is false
AND datname not IN ('postgres')) -- here you can exclude more databases
FROM the search
SELECT  dbs.datname
       ,array[(
SELECT  _res
FROM dblink
(dbs._link, 'select ''Tables: ''||coalesce( (string_agg( (
	SELECT  schemaname||''.''||tablename
	FROM pg_tables
	WHERE tablename like '''||pattern._mask||'''), '', '') ), ''none'')||''| ''|| ''Views: ''||coalesce( (string_agg( (
	SELECT  schemaname||''.''||viewname
	FROM pg_views
	WHERE viewname like '''||pattern._mask||'''), '', '') ), ''none'') AS _result'
) AS t1(_res text))] AS _res
FROM dbs, pattern