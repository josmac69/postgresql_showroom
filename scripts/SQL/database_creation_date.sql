-- We cannot find it directly but we can check attributes of directories which contain data files of each database.
-- In PostgreSQL you can try this query:

WITH mydir AS
(
	SELECT  setting||'/base' AS _dir
	FROM pg_settings
	WHERE name = 'data_directory'
), mydbs AS
(
	SELECT  oid AS _oid
	       ,datname
	FROM pg_database
), myfiles AS
(
	SELECT  _dir
	       ,pg_ls_dir(_dir) AS _file
	FROM mydir
), details AS
(
	SELECT  _dir
	       ,_file
	       ,(
	SELECT  datname
	FROM mydbs
	WHERE _oid::text = _file) AS _database,
    string_to_array(replace(replace(pg_stat_file(_dir||'/'||_file)::text, '(', ''), ')', ''), ',') AS _detail
	FROM myfiles
)
SELECT  _database
       ,_detail[1]::bigint    AS _size
       ,_detail[2]::timestamp AS _last_accessed
       ,_detail[3]::timestamp AS _last_modified
       ,_detail[4]::timestamp AS _last_file_status_change_unix_only
       ,_detail[5]::text      AS _file_creation_windows_only
       ,_detail[6]::boolean   AS _is_directory
       ,_dir
       ,_file
FROM details
ORDER BY _database