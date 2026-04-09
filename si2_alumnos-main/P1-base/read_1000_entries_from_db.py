import psycopg2
import time

db_config = {
    'dbname': 'si2db',
    'user': 'alumnodb',
    'password': 'alumnodb',
    'host': 'localhost',
    'port': 15432,
}

try:
    conn = psycopg2.connect(**db_config)
    cursor = conn.cursor()

    # Leer las primeras 1000 entradas
    cursor.execute("SELECT * FROM tarjeta LIMIT 1000")
    rows = cursor.fetchall()

    search_query = 'SELECT * FROM tarjeta WHERE "numero" = %s'

    # Medir tiempo
    start_time = time.time()

    for row in rows:
        id_value = row[0]
        cursor.execute(search_query, (id_value,))
        cursor.fetchone()

    end_time = time.time()

    print(f"Tiempo: {end_time - start_time:.6f} segundos")

except Exception as e:
    print(f"Error: {e}")
finally:
    if conn:
        cursor.close()
        conn.close()
