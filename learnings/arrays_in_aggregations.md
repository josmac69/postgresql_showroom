# Use arrays in aggregations

* If you get to know them you will simply love them – I mean ARRAYs in PostgreSQL.
* And also in some situations you simply cannot live without them – at least in PostgreSQL.

Here are some examples how to use them in real life.

* Aggregations from master-details tables or aggregations for time period or user session or machine IP etc. from one table
  * Common problem – you need to aggregate data to reduce number of records but you need to preserve different values from some column for further use.
  * Let’s presume this situation – you need to aggregate some events for time period and you need to preserve list of DISTINCT and NOT NULL values from some column

This crazy looking construct will do it during GROUP BY select:
```
select
"agg_columns....",
array(select distinct unnest(array_remove(array_agg("column_we_wish_to_aggregate"), null))) as "our_list_of_values"
from "source_table"
group by "agg_columns..."
```
Well maybe it looks cool but things are not simple… If you try to aggregate once more this already aggregated table into another one and you wish to reaggregate this list column, into another list column to get once more DISTINCT values over records you need to use slightly different construct. Basically you need to do this operation using TEXT type. Maybe this is some error in PostgreSQL and will be repaired. But so far on 9.3.5 other constructs did not work.
```
select
"agg_columns....",
array(select distinct unnest(string_agg("our_list_of_values"::text,',')::[])) as "our_new_list_of_values"
from "our_previuosly_aggregated_table"
group by "agg_columns...."
Of course if you use some of these hints you later may encounter situations when you need to make some operations with them
```
Intersection between two arrays:
If you for example need to check some special IDs like our servers/ region etc. against list of aggregated values.
```
select * from unnest("our_list_of_values") where unnest=any(SELECT oid FROM "some_list_of_values")
```
And do not forget to check extension “intarray” – it adds many useful array functions.
