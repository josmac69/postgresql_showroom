-- Do you need to know which columns take most disk space in your tables? Here is one useful statement:

WITH srcdata AS
(
	SELECT  table_schema||'.'||table_name                                  AS _table
	       ,column_name                                                    AS _column
	       ,COUNT(column_name) over (partition by table_schema,table_name) AS _column_count
	FROM information_schema.columns
	WHERE table_schema||'.'||table_name like '...schema.tablemask%...'
	ORDER BY table_schema, table_name
), results1 AS
(
	SELECT  *
	FROM srcdata
	JOIN lateral
	(
		SELECT  *
		FROM dblink
		('dbname=...your_database...'::text, 'select SUM(pg_column_size("'||_column||'"))::bigint AS total_size,
        AVG(pg_column_size("'||_column||'"))::numeric AS average_size, CASE WHEN pg_relation_size('''||_table||''') > 0
        THEN SUM(pg_column_size("'||_column||'")) * 100.0::numeric / pg_relation_size('''||_table||''') else 0 end AS percentage,
        pg_relation_size('''||_table||''')::bigint AS table_size
			FROM '||_table||''
		) AS t(total_size bigint, average_size numeric, percentage numeric, table_size bigint)
	) t
	ON true
), results2 AS
(
	SELECT  substr(_table,1,position('_' IN _table)) AS _tablename
	       ,_column
	       ,SUM(total_size)                          AS _total_column_size
	       ,AVG(average_size)                        AS average_column_size
	       ,SUM(table_size)                          AS _total_table_size
	       ,COUNT(_table)                            AS _tables_count
	FROM results1
	GROUP BY  substr(_table,1,position('_' IN _table))
	         ,_column
)
SELECT  _tablename
       ,_column
       ,round(_total_column_size::numeric / _total_table_size * 100,2) AS percentage
       ,round(average_column_size,2)                                   AS average_column_size
       ,_total_column_size
       ,_total_table_size
       ,_tables_count
FROM results2
ORDER BY percentage desc nulls last;
