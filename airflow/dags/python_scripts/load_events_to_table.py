import pandas as pd

from sqlalchemy import create_engine
from typing import Optional


def load_events_to_table(event_file_path: str, conn_url: str) -> Optional:
    """
    Load events csv file to postgres database
    :param event_file_path: absolute path of events csv file
    :param conn_url: connection url to postgresql database
    :return: None
    """
    engine = create_engine(f"postgresql://{conn_url}")

    df = pd.read_csv(event_file_path, header=0, sep=";")
    df[["service_id", "service_name_nl", "service_name_en", "service_lead_fee"]] = df["meta_data"].str.split(
        "_", expand=True
    )

    df = df.drop(columns=["meta_data"])

    df.to_sql("events", engine, if_exists="replace", index=False)

    engine.dispose()
