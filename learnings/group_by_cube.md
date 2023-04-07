# GROUP BY CUBE – experiences
PG 9.5 brought very useful addition to GROUP BY clause – CUBE. With CUBE you can get in very simple way aggregated results over all possible combinations of columns enlisted in CUBE. But everything has its price – so here are some experiences with CUBE.

First of all – query with GROUP BY CUBE runs longer than sequence of simple GROUP BYs with UNIONs producing the same output – difference depends on number of columns used in CUBE. So I cannot place any specific number here. But to write UNIONed partial GROUP BYs is ugly work with high possibility of errors – so I recommend CUBE every time…

There is one “small” gotcha about CUBE – if you do not replace NULL values of grouped columns you will have problem to distinguish in results cases when column had really NULL value and when NULL means ALL. So I recommend to make manual changes in query to make it look properly. Something like this (example presumes TEXT type of grouped columns):

```
select distinct
coalesce(col1,'all') as col1g, --- NULL in result means ALL values
coalesce(col2,'all') as col2g,
...here list of aggregated values...
from (
select
coalesce(col1,'unknown') as col1g, -- here we eliminate "real" NULLs in columns
coalesce(col2,'unknown') as col2g,
...here aggregated values...
from source_table
group by cube (col1g, col2g)
) a
```

I know it does not look very nice but this way you will have no problems with interpretation of results. One note about list of columns in CUBE – it uses aliases given to the columns in select or it can even take ordinal numbers of columns – like this: GROUP BY CUBE(1,

 So you do not need to repeat whole coalesce(…) commands there.
(Note – there seems to be a change in behavior in pg 9.6 – it is necessary to use column aliases different from original column names otherwise cube does not work properly. I found it when testing on new pg 9.6 selects which worked perfectly on old 9.5 but suddenly gave strange results. And these selects used the same aliases for coalesced results as original columns…)

Of course there is GROUPING function which you can use to create new column showing if row contains only values from records (value 0) or number showing (in binary form) over which columns are results summarized. This solution is clever but quite hard readable. So I recommend manually mask NULL values using coalesce – if it is possible regarding data types and values of grouped columns.

Replace CUBE with ROLLUP:

Some databases – like Bigquery – do not have CUBE command, only ROLLUP (in Legacy SQL to be precise – status 2016/10). How to simulate CUBE with ROLLUP?
ROLLUP does exactly what is says – it rolls up the summarization of aggregations – up from the last column in the list. So with columns in CUBE list c1, c2, c3 you will never get situation c1=all, c2, c3. These variants you must add to the query. Some databases allow you to add several ROLLUP parts into GROUP BY section in other databases you must add the whole new select as UNION DISTINCT.

So replacement of CUBE(c1,c2,c3) will look like this:
```
ROLLUP(c1,c2,c3)
ROLLUP(c2,c1,c3)
ROLLUP(c3,c2,c1)
ROLLUP(c2,c3,c1)
ROLLUP(c3,c1,c2)
```
quite ugly I guess 🙂

