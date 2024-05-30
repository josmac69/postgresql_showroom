import random
import psycopg2

# Connect to the PostgreSQL database
conn = psycopg2.connect(
    host="localhost",
    database="testindex",
    user="test",
    password="test"
)

# Create a cursor object to execute SQL queries
cur = conn.cursor()

# Generate and insert 1 million rows
for _ in range(1000000):
    array_length = random.randint(1, 20)
    array_values = [random.randint(1, 100) for _ in range(array_length)]
    jsonb_value = {"array_field": array_values}
    # print(str(jsonb_value))
    cur.execute("INSERT INTO my_table (jsonb_column) VALUES (%s)", (str(jsonb_value).replace("'", '"'),))

conn.commit()
conn.close()
