# Count according to condition
In old PostgreSQL 8 and 9 command like `SELECT count( column IS NOT NULL ) FROM table` is not working.

But you can always use SUM.

SUM + CAST: `SELECT sum( (column IS NOT NULL)::INT ) FROM table`
or SUM + CASE: `SELECT sum( CASE WHEN column IS NOT NULL THEN 1 ELSE 0 END) FROM table`


