-- For loop over VALUES
do $$
declare
i int; j int;
begin
for i,j in (values(1,2),(2,3),(3,4))  loop
raise NOTICE '%, %', i,j;
end loop;
end;
$$
language plpgsql;

-- One column in row:

select * from (values('myValue01'),('myValue02'),('myValue03')) as t(column1)

-- More columns in row:

select * from (values('myValue01', 1),('myValue02', 2),('myValue03', 3)) as t(column1, id)
