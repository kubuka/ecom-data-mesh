from airflow import DAG
from datetime import datetime, timedelta
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.models.connection import Connection
import boto3
import os

args = {"owner": "architect", "retries": 1, "retry_delay": timedelta(minutes=0.5)}


def upload_to_s3(**kwargs):
    aws_conn = Connection.get_connection_from_secrets(conn_id="aws_s3_conn")
    execution_date = kwargs["ds"]
    s3_client = boto3.client(
        "s3",
        region_name="eu-central-1",
        aws_access_key_id=aws_conn.login,
        aws_secret_access_key=aws_conn.password,
    )
    bucket_name = "ecom-data-mesh-bronze-layer"
    local_clickstream = (
        f'/opt/data/logs/clickstream_{execution_date.replace("-", "")}.json'
    )
    s3_clickstream = f"clickstream/event_date={execution_date}/clickstream.json"

    if os.path.exists(local_clickstream):
        s3_client.upload_file(local_clickstream, bucket_name, s3_clickstream)
        print("logs uploaded")
    else:
        print("logs not found")

    local_exchangerate = f"/opt/data/exchange_rate/fresh_exchange_rate_{execution_date.replace('-','')}.csv"
    s3_exchangerate = f"context_api/event_date={execution_date}/exchange_rate.csv"

    if os.path.exists(local_exchangerate):
        s3_client.upload_file(local_exchangerate, bucket_name, s3_exchangerate)
        print("exchange rate uploaded")
    else:
        print("exchange rate not found")

    local_coresystem = (
        f"/opt/data/core_system/orders_{execution_date.replace('-','')}.parquet"
    )
    s3_coresystem = f"core_system/event_date={execution_date}/orders.parquet"

    if os.path.exists(local_coresystem):
        s3_client.upload_file(local_coresystem, bucket_name, s3_coresystem)
        print("core orders uploaded")
    else:
        print("core orders not found")


with DAG(
    dag_id="ecom_data_pipeline",
    start_date=datetime(2026, 7, 5),
    schedule_interval="0 12 * * *",
    catchup=False,
    max_active_runs=1,
    default_args=args,
    tags=["bronze", "s3"],
) as dag:
    task_generate_db_entries = BashOperator(
        task_id="core_data_generate",
        bash_command="python /opt/airflow/scripts/core_data_generator.py",
    )

    task_generate_logs = BashOperator(
        task_id="logs_generate",
        bash_command="python /opt/airflow/scripts/click_stream_generator.py",
    )

    task_generate_exchange_rate = BashOperator(
        task_id="exrate_generate",
        bash_command="python /opt/airflow/scripts/exchange_rate_generator.py",
    )

    task_upload_s3 = PythonOperator(
        task_id="upload_files_to_s3", python_callable=upload_to_s3, provide_context=True
    )

    # dbt

    task_dbt_external_tables = BashOperator(
        task_id="dbt_refresh_external_tables",
        bash_command="dbt run-operation stage_external_sources --project-dir /opt/airflow/ecom_dbt --profiles-dir /opt/airflow/ecom_dbt",
    )

    task_dbt_run = BashOperator(
        task_id="dbt_run_transformations",
        bash_command="dbt run --project-dir /opt/airflow/ecom_dbt --profiles-dir /opt/airflow/ecom_dbt",
    )

    task_dbt_test = BashOperator(
        task_id="dbt_test_data_quality",
        bash_command="dbt test --project-dir /opt/airflow/ecom_dbt --profiles-dir /opt/airflow/ecom_dbt",
    )

    task_generate_db_entries >> task_generate_logs
    [task_generate_logs, task_generate_exchange_rate] >> task_upload_s3

    task_upload_s3 >> task_dbt_external_tables >> task_dbt_run >> task_dbt_test
