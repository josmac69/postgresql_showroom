# Hanging PostgreSQL session when called from external program
* If you see hanging PostgreSQL sessions for example from GO or node.js programs try to tune “keepalive” settings.
* Some libraries allow to use connection string parameters (keepalives, keepalives_idle, keepalives_interval, keepalives_count). But not all of them are implemented in different versions of these libraries (libraries then return error when parsing such connection string). If this is your case try to tune these settings directly in PostgreSQL settings (tcp_keepalives_count, tcp_keepalives_idle, tcp_keepalives_interval). If not explicitly set PostgreSQL takes defaults from OS. In case of Ubuntu/ Debian default for checking (“tcp_keepalive_time”) if client listens is 7200 seconds.

How to set values depends on your environment so look for example at:
* https://stackoverflow.com/questions/2166872/how-to-use-tcp-keepalives-settings-in-postgresql

Settings which we use:

* tcp_keepalives_idle = 120
* tcp_keepalives_interval = 60
* tcp_keepalives_count = 10