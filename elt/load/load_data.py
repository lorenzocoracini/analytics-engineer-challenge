import pandas as pd
from pathlib import Path
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
import os
import sys

sys.path.insert(0, str(Path(__file__).parent.parent))
from extract.extract_data import load_raw_csv, file

load_dotenv()

def create_schema(engine, schema_name):
    with engine.connect() as conn:
        conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema_name}"))
        conn.commit()

def load_to_postgres(df, schema_name, table_name):
    database_url = os.getenv("DATABASE_URL")
    engine = create_engine(database_url)
    
    create_schema(engine, schema_name)
    
    df.to_sql(table_name, engine, schema=schema_name, if_exists='replace', index=False)
    
    full_table_name = f"{schema_name}.{table_name}"
    print(f"Data loaded into {full_table_name}")
    
    result = pd.read_sql_table(table_name, engine, schema=schema_name)
    print(f"Verification: {len(result)} rows in database")

if __name__ == "__main__":
    csv_path = Path(__file__).parent.parent / file
    df = load_raw_csv(csv_path)
    load_to_postgres(df, schema_name="raw", table_name="loads_raw")