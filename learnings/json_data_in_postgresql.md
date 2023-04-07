# Playing with JSON data in PostgreSQL

still in TODO

Overview:

* JSON is right now very “fashionable” data format. And as they say “everyone uses it” or “it powers the whole web” etc.
* I remember times when XML format was “the coolest of all” and now it is called “your dad’s data format”.
* We will see where JSON will be in 10 years but right now it is “on top”.
* So let’s play with it in PostgreSQL…

*index over JSON:*

* string value:
  * create index index_name on table_name ((json_column->>’stringattribname’));
* number value:
  * create index index_name on table_name (cast(json_column->>’numericattribname’ as integer));   — or cast as different type – numeric etc.
* more json attributes in one index:
  * create index index_name on table_name ((json_column->>’attrib1′), (json_column->>’attrib1′), ….);

*select json values:*

->> operand (gives result as text)

* attribute on 1.level:
  * select myjson->>’attribname’ from ….
* attribute on 2.level:
  * select myjson->’level1attrib’->>’level2attrib’ from ….
* etc with more levels – only last level attribute name will have “->>” operand

#> operand (gives result as json / jsonb – depends on source):

* select myjson#>'{level1attrib, level2attrib}’

#>> operand (gives result as text):

* select myjson#>>'{level1attrib, level2attrib}’

*GIN indexes:*

//TODO
