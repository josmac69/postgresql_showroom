/*
Repair referenced sequences on tables
Lately I had to repair one interesting problem.
One colleague created staging schema and copied existing table structures
but did not change sequences referenced in default values for IDs.
So I had to repair it. I also had to set properly current value of staging sequences.
So I created following script:
*/
do $$
declare
	_rec record;
	_query_orig text;
	_seq_orig text;
	_seq_value_orig bigint;
	_query_new text;
	_seq_new text;
	_seq_value_new bigint;
	_pos int;
	_query text;
	_ret text;
begin
	for _rec in (
	SELECT table_schema, table_name, column_name, column_default from
	information_schema.columns where column_default is not null
	and lower(column_default) like 'nextval(''bi.%'
	and table_schema = 'bi_staging'
	order by column_default, table_schema, table_name)
	loop
		raise notice '%: >>> %.%.% -> %', clock_timestamp(), _rec.table_schema, _rec.table_name, _rec.column_name, _rec.column_default;
		_seq_orig := split_part(split_part(_rec.column_default,'''', 2),'''', 1);
		_query_orig := 'select last_value from '||_seq_orig;
		execute _query_orig into _seq_value_orig;
		raise notice '%: % -> %', clock_timestamp(), _query_orig, _seq_value_orig;
		_seq_new := replace(_seq_orig,'bi.','bi_staging.');
		_query_new := 'select last_value from '||_seq_new;
		execute _query_new into _seq_value_new;
		raise notice '%: % -> %', clock_timestamp(), _query_new, _seq_value_new;

		if _seq_value_orig > _seq_value_new then
			_query := 'SELECT setval('''||_seq_new||''', '||_seq_value_orig||')';
			raise notice '%: query: %', clock_timestamp(), _query;
			execute _query into _ret;
			raise notice '%: result: %', clock_timestamp(), _ret;
		end if;

		_query := 'alter table "'||_rec.table_schema||'"."'||_rec.table_name||'" alter column "'||_rec.column_name||
		'" set default nextval('''||_seq_new||'''::regclass)';
		raise notice '%: query: %', clock_timestamp(), _query;
		execute _query;
	end loop;
end;
$$ language plpgsql;
