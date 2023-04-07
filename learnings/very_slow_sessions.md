# Problem with “drowsy” sessions in PostgreSQL 9.6 on Debian 8
* When we switched from PostgreSQL 9.5 on Ubuntu 14.04 to PostgreSQL 9.6 on Debian 8 we suddenly started to experience strange problems with “drowsy” sessions. When database was under high load with many connected sessions from time to time happened that some session went into kind of “drowsiness” – was running very slowly, process mostly in S (sleeping) or D (uninterruptible sleep – usually IO wait) state causing only very low disk IO.

* Problem was discussed on pgsql-bug list and looks like problem is cased by using memory hugepages. In our case Ubuntu 14.04 has by default hugepages enabled (value “always”) but Debian 8 has default setting “madvise” –  means transparent hugepages (THP) are only enabled for memory regions that explicitly request hugepages using (as docu says).

* In the moment I experiment with different settings on 2 different instances to see which setting will be better.

* So far I can tell that disabling transparent hugepages caused really significant drop in performance – queries on huge tables were running ~30% longer.
* Change Debian THP setting to “always” improved performance significantly.
* But as was found by Oracle – there is a problem with THP if you have swap. Old hugepages were not swappable but THP are. So using THP with swap together can cause serious problems. But we do not use swap (default on Google cloud instance).
* Internet articles usually do not recommend to use transparent hugepages for PostgreSQL 9.4+. We have monitoring with node_exporter, Prometheus and Grafana so I will check how it works.

What to check when problem happens:

Make output from “perf”:
```
sudo perf top 1&>perf_top.txt 2&>perf_top_err.txt
sudo perf top -u postgres 1&>perf_top_postgres.txt 2&>perf_top_postgres_err.txt
```
(read here about installing perf and symbols)

* Check “top -c -u postgres” output to see details about process.
* Check “sudo iotop” to see disk IO caused by process.

How to set hugepages off:

* To check hugepages performance try these steps described on RedHat web:
  * you will need to install “systemtap” tool: `sudo apt-get install systemtap`
  * To check hugepage setting use: `cat /sys/kernel/mm/transparent_hugepage/enabled`

Another setting having influence on memory management is “zone_reclaim_mode”. Check it using:
`cat /proc/sys/vm/zone_reclaim_mode`

This setting according to documentation means:
```
Zone_reclaim_mode allows someone to set more or less aggressive approaches to
reclaim memory when a zone runs out of memory. If it is set to zero then no
zone reclaim occurs. Allocations will be satisfied from other zones / nodes
in the system.

This is value ORed together of

1 = Zone reclaim on
2 = Zone reclaim writes dirty pages out
4 = Zone reclaim swaps pages

zone_reclaim_mode is disabled by default. For file servers or workloads
that benefit from having their data cached, zone_reclaim_mode should be
left disabled as the caching effect is likely to be more important than
data locality.
```

To check existing hugepages: `cat /proc/meminfo | grep -i huge`

If hugepages are used you will see output like this (taken from Ubuntu 16.04):
```
AnonHugePages: 1959936 kB
HugePages_Total: 0
HugePages_Free: 0
HugePages_Rsvd: 0
HugePages_Surp: 0
Hugepagesize: 2048 kB
```

* variable “AnonHugePages” shows info about Transparent HugePages, other values are about standard hugepages

Transparent Hugepages are most modern version of hugepages and do not require any special settings neither in OS (just allowing then by setting to “always”) nor in applications. If your PostgreSQL is set to “try” hugapages it will start to use them.
To disable transparent hugepages:
```
echo 0 > /proc/sys/vm/zone_reclaim_mode
echo never > /sys/kernel/mm/transparent_hugepage/enabled
```
Another way how to disable transparent hugepages is described on stackoverflow:

install the sysfsutils package: `sudo apt install sysfsutils`

and append a line with that setting to /etc/sysfs.conf:
`kernel/mm/transparent_hugepage/enabled = never`

if you on the other hand want to set it to “always” change text in previous step accordingly
