# How to simulate deadlock in PostgreSQL

If you need to test for example locks or error handling during deadlock you can use following simple example to create deadlock situation. But be aware that this is deadlock “from school book”. Nice and clean and logical. Just to see “how it works”.

But in real life I had several cases of deadlocks on PG 8.4 which did not make any sense and I was never able to reproduce them again because of lack of detailed information. In PG 9.3 we have fortunately [new diagnostics for errors](https://web.archive.org/web/20210919011332/http://postgresql.freeideas.cz/use-stacked-diagnostics-to-check-error-details-also-check-of-deadlock-details/ "Use stacked diagnostics to check error details (+ check of deadlock details)") so higher chance to find out what’s going on. Only problem is when deadlock error is issued then as first step transaction with deadlock error is rollbacked and only after that you will have your chance to check error stack in your procedure. So you will see fully only “one player in the game” and will have to guess and try what was second process really doing…

For simulation I use for simplicity table config.users from my example application.

In first session prepare this statement:

```
begin
	begin
		update config.users set first_name='Joe' where id=1;

		perform pg_sleep(3);

		update config.users set first_name='Wolfgang' where id=2;

		perform pg_sleep(10);
	end;

exception when others then
 ....here your exception handling....
end;
```

In second session prepare the reverse statement with different updates:

```
begin
	begin
		update config.users set first_name='Andreas' where id=2;

		perform pg_sleep(3);

		update config.users set first_name='Thomas' where id=1;

		perform pg_sleep(10);
	end;

exception when others then
 ....here your exception handling....
end;
```

Now you have to run both statements very quickly one after another. After several seconds one of them will end with deadlock error. If not you must be quicker in launching them simultaneously.
