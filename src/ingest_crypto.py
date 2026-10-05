import requests
import pandas as pd
from google.cloud import bigquery
from dotenv import load_dotenv
load_dotenv()

def ingest_crypto_data():
    url = "https://api.coingecko.com/api/v3/coins/markets"
    params ={
        "vs_currency": "usd",
        "ids": "bitcoin,ethereum,ripple,litecoin,cardano",
    }
    response =requests.get(url,params=params,timeout= 10)
    response.raise_for_status()
    return response.json()
def load_crypto_data_to_bigquery(df):
    
    client = bigquery.Client(project="crypto-data-pipeline-510709")
    table_id = "crypto-data-pipeline-510709.crypto_raw.raw_prices"
    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
        schema=[
            bigquery.SchemaField("id", "STRING"),
            bigquery.SchemaField("price_checked_at", "TIMESTAMP"),
            bigquery.SchemaField("symbol", "STRING"),
            bigquery.SchemaField("name", "STRING"),
            bigquery.SchemaField("price_usd", "FLOAT"),
            bigquery.SchemaField("market_cap", "FLOAT"),
            bigquery.SchemaField("total_volume", "FLOAT"),
            bigquery.SchemaField("high_24h", "FLOAT"),
            bigquery.SchemaField("low_24h", "FLOAT"),
            bigquery.SchemaField("price_change_percentage_24h", "FLOAT"),
        ],
    )
    job = client.load_table_from_dataframe(df, table_id, job_config=job_config) 
    job.result()  # Wait for the job to complete
    print(f"✅ Loaded {df.shape[0]} rows into {table_id}")   
def dataframe_transform(data):
    row=[]
    for assets in data:
        row.append({
            "id": assets["id"],
            "price_checked_at": pd.Timestamp.now(tz="UTC"),
            "symbol": assets["symbol"],
            "name": assets["name"],
            "price_usd": assets["current_price"],
            "market_cap": assets["market_cap"],
            "total_volume": assets["total_volume"],
            "high_24h": assets["high_24h"],
            "low_24h": assets["low_24h"],
            "price_change_percentage_24h": assets["price_change_percentage_24h"]
        })
    df = pd.DataFrame(row)
    return df
def main():
    print("Fetching crypto prices...")
    data = ingest_crypto_data()
    df = dataframe_transform(data)
    print("\nCrypto data:")
    print(df)
    load_crypto_data_to_bigquery(df)


if __name__ == "__main__":
    main()