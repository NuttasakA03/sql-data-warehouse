import pandas as pd
import urllib.parse
import glob
from sqlalchemy import create_engine, text

#Connect to Database
obdc = (
    "DRIVER={ODBC DRIVER 17 for SQL Server};"
    "SERVER=localhost\\SQLEXPRESS;"
    "DATABASE=DataWareHouse;"
    "Trusted_Connection=yes;"
)

engine = create_engine(
    "mssql+pyodbc:///?odbc_connect=" + urllib.parse.quote_plus(obdc)
)

files = {
    "crm_cust_info": "source_crm/cust_info.csv",
    "crm_prd_info": "source_crm/prd_info.csv",
    "crm_sales_details": "source_crm/sales_details.csv",
    "erp_cust_az12": "source_erp/CUST_AZ12.csv",
    "erp_loc_a101": "source_erp/LOC_A101.csv",
    "erp_px_cat_g1v2": "source_erp/PX_CAT_G1V2.csv"
}

for table, path in files.items():
    df = pd.read_csv("../../../datasets/"+path, dtype=str)
    with engine.begin() as conn:
        conn.execute(text(f"TRUNCATE TABLE bronze.{table}"))
    df.to_sql(
        table, 
        schema = "bronze",
        con = engine,
        if_exists = "append",
        index = False
    )