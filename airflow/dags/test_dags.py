from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2023, 6, 24),
    'schedule_interval': '@daily',
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
        'sample_dag',
        default_args=default_args,
        schedule_interval=timedelta(days=1),
        catchup=False
) as dag:

    t1 = BashOperator(
        task_id='task_1',
        bash_command='echo "Hello, Airflow!"',
    )

    t2 = BashOperator(
        task_id='task_2',
        bash_command='echo "Running task 2"',
    )

    t3 = BashOperator(
        task_id='task_3',
        bash_command='echo "Running task 3"',
    )

    t1 >> t2 >> t3
