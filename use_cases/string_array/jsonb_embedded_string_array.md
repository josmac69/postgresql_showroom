For full text search or LIKE search on an array of strings, you can use the `GIN` index with the `pg_trgm` extension, which supports `gin_trgm_ops` operator class.
This extension provides functions and operators for determining the similarity of alphanumeric text based on trigram matching.

Here's an example:

1. Install the `pg_trgm` extension:

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

2. Create a table:

```sql
CREATE TABLE my_table_strarray (
    id serial primary key,
    jsonb_column jsonb
);
```

3. Insert some data:

```sql
INSERT INTO my_table_strarray (jsonb_column) VALUES
('{"array_field": ["apple", "banana", "cherry"]}'),
('{"array_field": ["banana", "cherry", "date"]}'),
('{"array_field": ["cherry", "date", "elderberry"]}');
```

4. Create a function to convert the JSONB array to a text array:

```sql
CREATE OR REPLACE FUNCTION jsonb_array_to_text_array(jsonb_array jsonb) RETURNS text[] AS $$
DECLARE
  text_array text[];
BEGIN
  SELECT ARRAY_AGG(elem::text) INTO text_array
  FROM jsonb_array_elements_text(jsonb_array) AS elem;
  RETURN text_array;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

5. Create the index:

```sql
CREATE INDEX idx_my_table_strarray_array_field ON my_table_strarray
USING gin (jsonb_array_to_text_array(jsonb_column -> 'array_field') gin_trgm_ops);
```

6. Test a select with full text search:

```sql
SELECT * FROM my_table_strarray
WHERE jsonb_array_to_text_array(jsonb_column -> 'array_field') @@ to_tsquery('banana');
```

This query will return the first two rows, as their `array_field` contains the word 'banana'.

For a LIKE search, you can use the `%` operator:

```sql
SELECT * FROM my_table_strarray
WHERE jsonb_array_to_text_array(jsonb_column -> 'array_field')::text LIKE '%banana%';
```

This will also return the first two rows. Note that the `LIKE` query will be case sensitive. If you want it to be case insensitive, use `ILIKE` instead.