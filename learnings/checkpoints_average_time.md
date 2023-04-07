# Average time interval between checkpoints
Calculates average delay between checkpoints.
```
SELECT
	total_checkpoints,
	seconds_since_start / total_checkpoints  AS seconds_between_checkpoints,
	seconds_since_start / total_checkpoints / 60 AS minutes_between_checkpoints,
	seconds_since_start
FROM
	(SELECT
		EXTRACT(EPOCH FROM (now() - pg_postmaster_start_time())) AS seconds_since_start,
		(checkpoints_timed+checkpoints_req) AS total_checkpoints
	FROM 	pg_stat_bgwriter
	) AS sub;
```
