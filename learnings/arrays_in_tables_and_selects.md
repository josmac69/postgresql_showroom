# Arrays in tables and selects
This very simple example shows how to use ARRAYs in tables and in selects:
```
create table temp.arraytest (
id bigserial,
fks bigint[]
);

create table temp.fks (
id bigserial,
something text
);

insert into temp.fks (something) values ('line1'),('line2'),('line3');

select * from temp.fks;
"id";"something"
1;"line1"
2;"line2"
3;"line3"


insert into temp.arraytest (fks) values (array[1,2]);

select * from temp.arraytest;

"id";"fks"
1;"{1,2}"

select * from temp.fks
where id in (select unnest(fks) from temp.arraytest where id=1);
```
