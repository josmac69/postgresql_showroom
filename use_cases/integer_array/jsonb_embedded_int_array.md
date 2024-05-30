
1. Create a table:

```sql
CREATE TABLE my_table (
    id serial primary key,
    jsonb_column jsonb
);
```

2. Insert some data:

```sql
INSERT INTO my_table (jsonb_column) VALUES
('{"array_field": [1, 2, 3]}'),
('{"array_field": [2, 3, 4]}'),
('{"array_field": [3, 4, 5]}');
```

3. Create the function to convert the JSONB array to an integer array:

```sql
CREATE OR REPLACE FUNCTION jsonb_array_to_int_array(jsonb_array jsonb) RETURNS int[] AS $$
DECLARE
  int_array int[];
BEGIN
  SELECT ARRAY_AGG(elem::int) INTO int_array
  FROM jsonb_array_elements_text(jsonb_array) AS elem;
  RETURN int_array;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
```

4. Create the index:

```sql
CREATE INDEX idx_my_table_array_field ON my_table
USING gin (jsonb_array_to_int_array(jsonb_column -> 'array_field') gin__int_ops);
```

5. Test a select:

```sql
SELECT * FROM my_table
WHERE jsonb_array_to_int_array(jsonb_column -> 'array_field') @> ARRAY[2,3];
```

This query will return the first two rows, as their `array_field` contains both 2 and 3.

Please note that you need to have the `intarray` extension installed for the `gin__int_ops` operator class. You can do this by running:

```sql
CREATE EXTENSION IF NOT EXISTS intarray;
```
