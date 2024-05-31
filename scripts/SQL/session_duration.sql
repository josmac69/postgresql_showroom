-- duration of running sessions

SELECT
    pid,
    usename,
    application_name,
    state,
    backend_start,
    query_start,
    state_change,
    now() - backend_start AS backend_duration,
    now() - query_start AS query_duration,
    now() - state_change AS state_change_duration
FROM
    pg_stat_activity
WHERE
    state = 'active'
ORDER BY
    backend_duration DESC;

