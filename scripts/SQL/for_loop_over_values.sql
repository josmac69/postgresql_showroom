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
