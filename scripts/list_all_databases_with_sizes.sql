-- you can also use \l+ command in psql
-- if you do not have psql installed you can use following select in any db gui

SELECT  datname                                   AS "database"
       ,pg_database_size(datname)                 AS "database_size_bytes"
       ,pg_size_pretty(pg_database_size(datname)) AS "database_size"
FROM pg_database
WHERE datistemplate = false
ORDER BY "database"