import pandas as pd
from pathlib import Path

file = 'data/2026_data_challenge_ae_data.csv'

def extract_raw_csv(filepath):
    df = pd.read_csv(filepath)
    
    print(f"CSV File extracted : {len(df)} rows")
    print(f" 5 first rows of the CSV file:")
    print(df.head())
    
    return df

if __name__ == "__main__":
    csv_path = Path(__file__).parent.parent / file
    df = extract_raw_csv(csv_path)