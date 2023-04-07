# Out of shared memory error

This error you get when you create in one moment too many locks on tables in all transactions together.

Situation when I encountered it was – many parallel queries from parent table with cca 100 child tables.
Error looks like this:
```
WARNING:  out of shared memory
ERROR:  out of shared memory
HINT:  You might need to increase max_locks_per_transaction.
STATEMENT:  …….
```

Especially line “STATEMENT: ” is important. Here you can see what caused error. But solution may not be as simple as “HINT” suggests. Parameter “max_locks_per_transaction” globally says how big part of shared memory is allocated for “lock table” in shared memory. But error can also mean that you consumed all shared memory which PostgreSQL can use.

I recommend to check the overall situation about memory on machine.

check all shared memory Linux parameters:
```
sudo sysctl -a 2>/dev/null|grep -E '^kernel.shm.*'
```
Or in more human readable form:
```
free && ipcs -l && echo "page size:" && getconf PAGE_SIZE
```
which will show you all about available memory, settings for shared memory and also page size on your distro

where:
max number of segments = SHMMNI
max seg size (kbytes) = SHMMAX
max total shared memory (kbytes) = SHMALL

* Some Linux distros do not use SHMSEG parameter (number of shared memory segments allowed to be allocated by one process) and use SHMMNI instead of it.
  * If you are not sure about architecture of your Linux (meaning 32/64 bits), try this:
```
uname -m
x86_64 = 64 bit
```

You may also try to check usage of shared memory in top command
* run “top -c”
* or “top -c -u postgres” – to see only postgresql processes
press “f”
use arrows to move to SHR line
press “s” + “q”
you will now see running processes sorted by usage of shared memory

* if you did not use postgres too seriously or restarted service you will see very probably that highest shared memory consumption has plain “postgresql” server process
* After some serious usage usually “postgres: checkpointer process” has one of highest shared memory consuption. If it is very close to your “shared_buffers” setting then you might consider to increase “shared_buffers”
* Be aware that simple increase of the value in parameter “max_locks_per_transaction” can cause another error:
```
FATAL: could not create shared memory segment: No space left on device
```
  * Which means that PostgreSQL could not allocate enough shared memory from SHMMAX Linux limit because all Linux shared memory was used.

Note about “max_locks_per_transaction”:

* Documentation says that max number of locked objects is calculated as “max_locks_per_transaction * (max_connections + max_prepared_transactions) “. Every lock is stored in shared memory therefore with too high settings we can get second error when system will not be able to allocate more memory for its shared memory.
* On the other hand my tests showed that real number of locks stored in shared memory can be much higher than settings suggests. Documentation says that it depends on amount of data stored for every lock.

Be aware that change in this setting requires restart of the database.

