# Convert ARRAY to rows

* Simple command “unnest” changes every ARRAY regardless of how many dimensions it has into “one element per row” format.
```
WITH data AS (
    SELECT '{ {"COLOUR_SCHEME", "RASPBERRY_BLISS"}, {"FONT", "TERMES_HEROS"}, {"LIST_LAYOUT", "BULLET_SNOWFLAKE"} }'::text[] AS arr
)
SELECT unnest(arr) from data;
```

* If you want to make more columns you have to make it manually:
```
WITH data AS (
    SELECT '{ {"COLOUR_SCHEME", "RASPBERRY_BLISS"}, {"FONT", "TERMES_HEROS"}, {"LIST_LAYOUT", "BULLET_SNOWFLAKE"} }'::text[] AS arr
)
SELECT
    arr[i][1] AS aspect,
    arr[i][2] AS preference
FROM
    data,
    generate_subscripts((SELECT arr FROM data), 1) i;
```
