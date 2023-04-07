-- Processes waiting for lock – PostgreSQL 9.3
-- Query is similar as for pg 8.4 but with small differences in column names because of changes in pg_stat_activity in pg 9.3

with locks as (
	with sourcedata as (
		select 	l.pid as connection_id,
			a.datname as "database",
			case when a.waiting is false then 'locks'
			else 'waits' end as query_lock_status,
			case when l.granted is true then 'held'
			else 'awaited' end as lock_granted,
			l.transactionid,
			l.virtualxid,
			l.virtualtransaction,
			l.locktype,
			l.mode as lock_mode,
			case relkind
			when 'r' then 'table'
			when 'i' then 'index'
			when 'S' then 'sequence'
			when 'v' then 'view'
			when 'c' then 'composite type'
			when 't' then 'TOAST table'
			else relkind||'?'
			end ||': '||
			ns.nspname ||'.'||c.relname as "locked_object",
			a.query,
			a.xact_start as transaction_start,
			a.query_start,
			a.backend_start as connection_start
		from 	pg_locks l
		left join pg_database d
		on 	l.database = d.oid
		left join pg_class c
		on 	l.relation = c.oid
		left join pg_namespace ns
		on	c.relnamespace = ns.oid
		left join pg_stat_activity a
		on 	l.pid = a.pid
		where 	l.pid <> pg_backend_pid()
			and locktype not in ( 'virtualxid', 'tuple')
		)
	select 	connection_id,
		"database",
		query_lock_status,
		lock_granted,
		transactionid,
		(select 'connection='||connection_id||', query= '||substr(query,1,100) from sourcedata src0 where src0.lock_granted = 'held' and src0.transactionid = src.transactionid and src0.connection_id<>src.connection_id) as lock_held_by,
		locktype,
		(select array_agg("locked_object") from (select * from sourcedata order by "locked_object") src0 where src0.connection_id=src.connection_id and src0.virtualtransaction=src.virtualtransaction and locktype='relation') as "locked_objects",
		virtualtransaction,
		query,
		transaction_start
	from sourcedata src
	group by query_lock_status, connection_id, "database", query_lock_status, lock_granted, transactionid, locktype, virtualtransaction, query, transaction_start--, case when
	)
select connection_id, "database", substr(query,1,40) as wants_to_run, "locked_objects" as "wants_to_lock", lock_held_by
from locks
where locktype<>'relation' and lock_granted = 'awaited'
order by transaction_start desc
