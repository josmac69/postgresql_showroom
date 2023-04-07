# Block some user from connecting into PostgreSQL
* Lately I started to see in postgresql log brute force attacks on postgres user:
```
2019-03-07 08:12:57.064 UTC [24942] postgres@postgres FATAL: password authentication failed for user “postgres”
2019-03-07 08:12:57.064 UTC [24942] postgres@postgres DETAIL: User “postgres” has no password assigned.
Connection matched pg_hba.conf line 92: “host all all 0.0.0.0/0 md5”
2019-03-07 08:12:57.934 UTC [24943] postgres@postgres FATAL: password authentication failed for user “postgres”
2019-03-07 08:12:57.934 UTC [24943] postgres@postgres DETAIL: User “postgres” has no password assigned.
Connection matched pg_hba.conf line 92: “host all all 0.0.0.0/0 md5”
```
* We use local only peer authentication for postgres and user has no password assigned. But since we have many users pg_hba.conf files contains this line:
```
host all all 0.0.0.0/0 md5
```
* To block postgres connections from outside I added before this line new configuration:
```
host all postgres 0.0.0.0/0 reject
```
* This way any login attempts of postgres user from any IP outside are blocked and postgresql log is now flooded with these messages:
```
2019-03-07 08:19:42.654 UTC [31196] postgres@postgres FATAL: pg_hba.conf rejects connection for host “159.203.123.11”, user “postgres”, database “postgres”, SSL off
```
