import os
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from python_scripts.create_postgres_table import create_table
from python_scripts.queries import create_event_table
from python_scripts.load_events_to_table import load_events_to_table


def generate_dag(schedule_interval: str) -> DAG:
    """
    Generate DAG for events pipeline based on schedule interval
    :param schedule_interval: schedule interval for DAG
    :return: DAG object
    """
    default_args = {
        "owner": "data_team",
        "start_date": datetime(2023, 6, 24),
        "schedule_interval": schedule_interval,
        "retries": 1,
        "retry_delay": timedelta(minutes=5),
    }

    with DAG(
        f"events_pipeline_{schedule_interval[1:]}",
        default_args=default_args,
        schedule_interval=schedule_interval,
        catchup=False,
    ) as dag:

        create_table_if_not_exist = PythonOperator(
            task_id="create_table_if_not_exist",
            python_callable=create_table,
            op_args=[[create_event_table], os.getenv("POSTGRES_CONN")],
        )

        load_data_to_table = PythonOperator(
            task_id="load_data_to_table",
            python_callable=load_events_to_table,
            op_args=["/opt/airflow/data/event_log.csv", os.getenv("POSTGRES_CONN")],
        )

        create_table_if_not_exist >> load_data_to_table

    return dag


intervals = ["@daily", "@weekly", "@monthly"]
for interval in intervals:
    generate_dag(interval)
