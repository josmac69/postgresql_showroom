import psycopg2
import sys
import pprint
import os
import datetime

def main():
    # Set parameters
    filename_comment = 'new_inst_v202'
    hostname =  "xxx.xxx.xxx.xxx"
    date = str(datetime.date.today())

    # Create file name
    filename =  f"d:/export/all_objects_{hostname}-{date}-{filename_comment}.sql"
    print(filename)

    # Open file for writing
    with open(filename, 'w') as f:
        userpass = " user='xxxxxxx' password='xxxxxxxx'"
        pg_conn_string = f"host='{hostname}' dbname='postgres'{userpass}"
        pg_conn = psycopg2.connect(pg_conn_string)
        dbs_cursor = pg_conn.cursor()

        # Select databases
        dbs_cursor.execute("select datname from pg_database where datistemplate is false and datname not in ('postgres', 'test') order by datname")
        dbs_records = dbs_cursor.fetchall()
        pg_conn.close()

        # Loop through databases
        for database in dbs_records :
            dbname = database[0]
            title = f"************************** database {dbname} *************************************"
            f.write(f"{title}\n\n")
            conn_string = f"host='{hostname}' dbname='{dbname}'{userpass}"
            print(f"{dbname} -> {conn_string}")

            # Connect to database and get cursor
            try:
                with psycopg2.connect(conn_string) as conn:
                    with conn.cursor() as cursor:
                        # Export all functions
                        cursor.execute("select s.nspname, p.proname, pg_get_functiondef(p.oid) from pg_proc p join pg_namespace s on p.pronamespace=s.oid where nspname not in ('pg_catalog', 'information_schema') order by s.nspname, p.proname, p.proargnames, p.proargtypes")
                        records = cursor.fetchall()

                        # Export all function code
                        f.write("-------------- functions -------------\n")
                        for line in records :
                            f.write(f"*** {dbname}.")
                            for x in line :
                                towrite = str(x)
                                towrite = towrite.replace('\r\n', '\n')
                                f.write(f"{towrite}\n")

                        # Export all views
                        cursor.execute("select schemaname, viewname, definition from pg_views where schemaname not in ('information_schema', 'pg_catalog') order by schemaname, viewname")
                        records = cursor.fetchall()

                        f.write("-------------- views -------------\n")
                        for line in records :
                            f.write(f"*** {dbname}.")
                            for x in line :
                                towrite = str(x)
                                towrite = towrite.replace('\r\n', '\n')
                                f.write(f"{towrite}\n")

                        # Check table columns
                        cursor.execute("SELECT table_schema
