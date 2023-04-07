# Check available / installed extensions

* extensions available to be installed on the database:
  ```
  select * from pg_available_extensions;
  ```
* installed extensions:
  ```
  select * from pg_extension;
  ```
