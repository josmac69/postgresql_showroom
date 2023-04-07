select
	extract(epoch from clock_timestamp()) as present_time_unix,
	to_timestamp( extract(epoch from clock_timestamp())) as present_time_unix_back_to_postgresql