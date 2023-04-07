# bgwriter statistic in PostgreSQL 8.4
If you need to check what is PostgreSQL really doing – reads, writes, etc. you can try bgwriter statistic in pg_stat_bgwriter
Only problem is that PG 8.4 does not store history therefore you need to save some time snapshots.

First – create table for time snapshots:
```
create table public.systemcheck_stat_bgwriter as
select clock_timestamp() as log_datum, * from pg_stat_bgwriter;
```
Second – insert time snapshots – manually any time you want or using some program with timer:
```
insert into public.systemcheck_stat_bgwriter
select clock_timestamp() as log_datum, * from pg_stat_bgwriter;
```

When you gather some time snapshots you can analyze data with this select:

```
with sourcedata as (
	select
		s.log_datum,
		extract(epoch from (s.log_datum - lag(s.log_datum,1) over (order by s.log_datum))) as time_diff_seconds,
		s.checkpoints_timed - lag(s.checkpoints_timed, 1) over (order by s.log_datum) as checkpoints_timed_diff,
		s.checkpoints_req - lag(s.checkpoints_req, 1) over (order by s.log_datum) as checkpoints_req_diff,
		s.buffers_checkpoint - lag(s.buffers_checkpoint, 1) over (order by s.log_datum) as buffers_checkpoint_diff,
		s.buffers_clean - lag(s.buffers_clean, 1) over (order by s.buffers_clean) as buffers_clean_diff,
		s.maxwritten_clean - lag(s.maxwritten_clean, 1) over (order by s.maxwritten_clean) as maxwritten_clean_diff,
		s.buffers_backend - lag(s.buffers_backend, 1) over (order by s.buffers_backend) as buffers_backend_diff,
		s.buffers_alloc - lag(s.buffers_alloc, 1) over (order by s.buffers_alloc) as buffers_alloc_diff,
		s.checkpoints_timed,
		s.checkpoints_req,
		s.buffers_checkpoint,
		s.buffers_clean,
		s.maxwritten_clean,
		s.buffers_backend,
		s.buffers_alloc
	from public.systemcheck_stat_bgwriter s)
select
	src.log_datum
	,
	src.time_diff_seconds
	,
	(src.buffers_checkpoint_diff + src.buffers_clean_diff + src.buffers_backend_diff)*8*1024
	as total_writes_bytes
	,
	round(cast((src.buffers_checkpoint_diff + src.buffers_clean_diff + src.buffers_backend_diff)as numeric)*8*1024/(1024*1024),6)
	as total_writes_MB
	,
	case when coalesce(src.time_diff_seconds,0) > 0 then
		round(cast((src.buffers_alloc_diff/src.time_diff_seconds*8*1024) as numeric),2)
	else null end
	as buffers_alloc_per_second_byte
	,
	case when coalesce(src.time_diff_seconds,0) > 0 then
		round(cast((src.buffers_alloc_diff/src.time_diff_seconds*8*1024/(1024*1024)) as numeric),6)
	else null end
	as buffers_alloc_per_second_MB
	,
	case when coalesce(src.time_diff_seconds,0) > 0 then
		round(cast(((src.buffers_checkpoint_diff + src.buffers_clean_diff + src.buffers_backend_diff)*8*1024/src.time_diff_seconds ) as numeric),2)
	else null end
	as total_writes_per_second_byte
	,
	case when coalesce((checkpoints_timed_diff + checkpoints_req_diff),0) > 0 then
		(src.buffers_checkpoint_diff/(checkpoints_timed_diff + checkpoints_req_diff))*8*1024
	else null end
	as avg_checkpoint_write_byte
	,
	case when coalesce((checkpoints_timed_diff + checkpoints_req_diff),0) > 0 then
		(100*checkpoints_timed_diff/(checkpoints_timed_diff + checkpoints_req_diff))
	else null end
	as checkpoint_timed_proc
	,
	case when coalesce((src.buffers_checkpoint_diff + src.buffers_clean_diff + src.buffers_backend_diff),0)>0 then
		src.buffers_checkpoint_diff/(src.buffers_checkpoint_diff + src.buffers_clean_diff + src.buffers_backend_diff)*100
	else null end
	as buffers_checkpoint_proc
	,
	case when (src.buffers_checkpoint_diff + src.buffers_clean_diff + src.buffers_backend_diff)>0 then
		src.buffers_clean_diff/(src.buffers_checkpoint_diff + src.buffers_clean_diff + src.buffers_backend_diff)*100
	else null end
	as buffers_clean_proc
	,
	case when (src.buffers_checkpoint_diff + src.buffers_clean_diff + src.buffers_backend_diff)>0 then
		src.buffers_backend_diff/(src.buffers_checkpoint_diff + src.buffers_clean_diff + src.buffers_backend_diff)*100
	else null end
	as buffers_backend_proc
	,
	case when coalesce(src.time_diff_seconds,0) > 0 then
		round(cast((src.maxwritten_clean_diff/src.time_diff_seconds*8*1024) as numeric),2)
	else null end
	as maxwritten_clean_per_second_byte
	,
	case when coalesce((checkpoints_timed_diff + checkpoints_req_diff),0) > 0 then
		(src.time_diff_seconds/(checkpoints_timed_diff + checkpoints_req_diff))
	else null end
	as seconds_per_checkpoint
	,
	src.checkpoints_timed_diff,
	src.checkpoints_req_diff,
	src.buffers_checkpoint_diff,
	src.buffers_clean_diff,
	src.maxwritten_clean_diff,
	src.buffers_backend_diff,
	src.buffers_alloc_diff,
	src.checkpoints_timed,
	src.checkpoints_req,
	src.buffers_checkpoint,
	src.buffers_clean,
	src.maxwritten_clean,
	src.buffers_backend,
	src.buffers_alloc
from sourcedata	src
order by log_datum;
```
