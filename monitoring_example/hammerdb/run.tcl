puts "Testing PostgreSQL"

dbset db pg
dbset bm TPC-C

diset connection pg_host postgres
diset connection pg_port 5432
diset tpcc pg_dbase postgres
diset tpcc pg_user postgres
diset tpcc pg_pass postgres

vuset logtotemp 1
vuset vu 1

vucreate
vurun
vudestroy

puts "test completed"
exit
