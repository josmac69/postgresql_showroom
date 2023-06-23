puts "Preparing PostgreSQL environment"

global complete
proc wait_to_complete {} {
global complete
set complete [vucomplete]
if {!$complete} {after 5000 wait_to_complete} else { exit }
}

dbset db pg
dbset bm TPC-C

diset connection pg_host postgres
diset connection pg_port 5432
diset tpcc pg_dbase postgres
diset tpcc pg_user postgres
diset tpcc pg_pass postgres

print dict
buildschema
wait_to_complete

puts "preparations done"

exit
