import psycopg2
from typing import Optional, List


def create_table(table_queries: List, conn_url: str) -> Optional:
    """
    Create table in postgresql database
    :param table_queries: an array of table creation queries
    :param conn_url: connection url to postgresql database
    :return: None
    """
    conn = psycopg2.connect(f"postgres://{conn_url}")
    cur = conn.cursor()

    for table_query in table_queries:
        cur.execute(table_query)

    conn.commit()
    conn.close()

    print("Table created successfully in PostgreSQL db")
