# pg_barman – check HW config of a server / instance
This simple script lists important HW info about a server or cloud instance + pg version + pg tablespaces in simple INI format. If you store output into file you can process it with other program to extract necessary info in even better form. These information you will need in case your server dies and you will have to know disks configuration and postgresql.

```
#!/usr/bin/env bash

pgserver=$(hostname -f)

echo "[config]"

echo "hostname=$pgserver"$'\n'

# cpu cores count
echo "cpu=$(grep -c ^processor /proc/cpuinfo)"$'\n'

# memory statistics
echo 'memory="""'
free
echo $'"""\n'

# /etc/fstab content
echo 'fstab="""'
cat /etc/fstab
echo $'"""\n'

# mounted disks by df
echo 'df="""'
df
echo $'"""\n'

#mounted disks by df in human readable form
echo 'df_h="""'
df -h
echo $'"""\n'

#mounted disks - system info
echo 'proc_mounts="""'
cat /proc/mounts
echo $'"""\n'

#postgresql tablespaces
psqlexists=$(command -v psql|wc -l)
if [[ $psqlexists -eq 1 ]]; then
  echo "postgresql=\"$(sudo su -c "psql -t -c \"select version()\"" postgres)\""$'\n'
  echo 'tablespaces="""'
  sudo su -c "psql -c \"select oid, spcname, pg_tablespace_location(oid) from pg_tablespace;\"" postgres
  echo $'"""\n'

  echo 'pg_directories="""'
  sudo su -c "psql -c \"select name,setting from pg_settings where name like '%dir%';\"" postgres
  echo $'"""\n'
else
  echo "postgresql=psql command not found"
fi
```
