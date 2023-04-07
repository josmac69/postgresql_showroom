-- Event triggers in PostgreSQL 11
-- Based on documentation and several different examples on web I created this code
-- for event triggers for PG 11. Maybe it can be useful for someone else too:

--- auditing table ---

CREATE TABLE IF NOT EXISTS
public.ddl_history (ddl_date TIMESTAMP, ddl_tag TEXT, object_name TEXT, username TEXT, fullcommand TEXT);

grant select, insert on table public.ddl_history to public;

--- create function for event trigger ---

create or replace function public.log_ddl() returns event_trigger as
$$
declare
	r RECORD;
	rtext text;
BEGIN
	FOR r IN SELECT * FROM pg_event_trigger_ddl_commands()
	LOOP
	  BEGIN
	    rtext := r.classid::text||','||r.objid||','||r.objsubid||','||r.command_tag||','||
		r.object_type||','||r.schema_name||','||r.object_identity||','||r.in_extension;
		INSERT INTO public.ddl_history (ddl_date, ddl_tag, object_name, username, fullcommand)
		VALUES (statement_timestamp(), tg_tag, r.object_identity, current_user, rtext);
	  EXCEPTION WHEN OTHERS THEN
		raise notice 'error in public.log_ddl trigger: % - %', SQLSTATE, SQLERRM;
	  END;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

--- create event trigger ---

DROP EVENT TRIGGER IF EXISTS log_ddl_history;

CREATE EVENT TRIGGER log_ddl_history ON ddl_command_end EXECUTE procedure public.log_ddl();

--- create function for event trigger on drop ---

CREATE OR REPLACE FUNCTION public.log_ddl_drop() RETURNS event_trigger AS $$
DECLARE
  r RECORD;
BEGIN
		FOR r IN SELECT * FROM pg_event_trigger_dropped_objects() LOOP
		  BEGIN
			INSERT INTO public.ddl_history (ddl_date, ddl_tag, object_name, username, fullcommand)
			VALUES (statement_timestamp(), tg_tag, r.object_identity, current_user, r);
		  EXCEPTION WHEN OTHERS THEN
			raise notice 'error in public.log_ddl_drop trigger: % - %', SQLSTATE, SQLERRM;
		  END;
		END LOOP;
END; $$ LANGUAGE plpgsql;

--- create event trigger for drop ---

DROP EVENT TRIGGER IF EXISTS log_ddl_drop_info;

CREATE EVENT TRIGGER log_ddl_drop_info ON sql_drop EXECUTE PROCEDURE public.log_ddl_drop();

/*
--- commands for testing ---

create schema if not exists temp;
drop table temp.temp_20201007;
create table temp.temp_20201007 (id serial, textvalue text);
alter table temp.temp_20201007 add column newcol int;

select * from public.ddl_history
--where object_name = 'temp.temp_20201007'
order by 1 desc
limit 20;

select ddl_tag, username, count(*) as cnt
from public.ddl_history
group by 1,2
order by 1,2;
*/