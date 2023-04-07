
# file_fdw extension small hints

Extension file_fdw is a very useful extension which allows you to read data directly from CSV file and query them using standard SQL. Data from file behave like from table.

Presume we have CSV file like this:
```
"id";"shop";"date";"metric";"value"
1;"myshop";"2017-01-01";"unique-visits";122......
```

This is very simple example just to demonstrate how things work. In reality we will have usually much more complicated data.

We create extension and foreign server like this:

```
create extension file_fdw;
CREATE SERVER files FOREIGN DATA WRAPPER file_fdw;
```

Extension file_fdw is standard part of postgresql so we do not need to install anything. Also foreign server for this extension will be created only once – it will work for all files on your server/instance because filename is part of foreign table definition – see bellow.

Now create foreign table which reads data from the file. To just read data from CSV file for further work with them it is the best to use type TEXT for all columns. I recommend never trust any CSV file with presumptions like “id will always be number” etc.
```
CREATE FOREIGN TABLE myschema.mycsvdata (
"id" text, "shop" text, "date" text, "metric" text, "value" text
) server files
OPTIONS ( filename '/my/path/filename.csv', format 'csv', delimiter ';', header 'true', null '<NULL>');
```
Now you can select from “myschema.mycsvdata” table and work with data further….