-- This simple extension helps you to determine possible problems with amount of pages/ tuples during query run.
-- Here is query which shows basic statistics for table:

WITH obj AS
(
	SELECT  '...schame.tablename....'::text AS _name
), srcdata AS
(
	SELECT  *
	FROM obj o
	JOIN lateral
	(
		SELECT  *
		       ,(
		SELECT  pg_relpages
		FROM pg_relpages
		(o._name
		) ) AS pg_relpages
		FROM pgstattuple
		( o._name
		)
	) a
	ON true
)
SELECT  tuple_len/tuple_count   AS _row_len
       ,tuple_count/pg_relpages AS tuples_per_page
       ,*
FROM srcdata