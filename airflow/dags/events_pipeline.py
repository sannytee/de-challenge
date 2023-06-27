import os
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import (
    KubernetesPodOperator,
)
from kubernetes.client import models as k8s
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
    volume = k8s.V1Volume(
        name="dbt-volume", host_path=k8s.V1HostPathVolumeSource(path="/usr/local/de-challenge/instapro_dbt")
    )

    volume_mount = k8s.V1VolumeMount(name="dbt-volume", mount_path="/usr/local/dbt", sub_path=None, read_only=False)

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

        # Right now, we are currently running all the dbt models. This is because the models are quite small and
        # are related to the the events pipeline. In production, we can run the models using tags.
        dbt_run = KubernetesPodOperator(
            namespace="airflow",
            task_id="run_dbt_models",
            in_cluster=True,
            image="ghcr.io/dbt-labs/dbt-postgres:1.5.1",
            get_logs=True,
            name="dbt-run",
            cmds=["/bin/bash", "-c", "dbt run --target prod"],
            volumes=[volume],
            volume_mounts=[volume_mount],
            env_vars={
                "DBT_PROFILES_DIR": "/usr/local/dbt",
                "DBT_PROJECT_DIR": "/usr/local/dbt",
            },
        )

        create_table_if_not_exist >> load_data_to_table >> dbt_run

    return dag


intervals = ["@daily", "@weekly", "@monthly"]
for interval in intervals:
    generate_dag(interval)
