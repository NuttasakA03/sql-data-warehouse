import pandas as pd
import urllib.parse
from sqlalchemy import create_engine

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

# Extract Data From dataset
crm_cust_info = pd.read_csv("../../../datasets/source_crm/cust_info.csv")
crm_prd_info = pd.read_csv("../../../datasets/source_crm/prd_info.csv")
crm_sales_details = pd.read_csv("../../../datasets/source_crm/sales_details.csv")
erp_cust_az12 = pd.read_csv("../../../datasets/source_erp/CUST_AZ12.csv")
erp_loc_a101 = pd.read_csv("../../../datasets/source_erp/LOC_A101.csv")
erp_px_cat_g1v2 = pd.read_csv("../../../datasets/source_erp/PX_CAT_G1V2.csv")

# --------- Load Data into Table ----------------

#--------- CRM -----------------
# cust_info
crm_cust_info.to_sql(
    "crm_cust_info",
    schema = "bronze",
    con = engine,
    if_exists = "replace",
    index = False 
)

# prd_info
crm_prd_info.to_sql(
    "crm_prd_info",
    schema = "bronze",
    con = engine,
    if_exists = "replace",
    index = False
)

# sales_details
crm_sales_details.to_sql(
    "crm_sales_details",
    schema = "bronze",
    con = engine,
    if_exists = "replace",
    index = False
)

# ------- ERP ---------------
# CUST_AZ12
erp_cust_az12.to_sql(
    "erp_cust_az12",
    schema = "bronze",
    con = engine,
    if_exists = "replace",
    index = False
)

# LOC_A101
erp_loc_a101.to_sql(
    "loc_a101",
    schema = "bronze",
    con = engine,
    if_exists = "replace",
    index = False
)

# PX_CAT_G1V2
erp_px_cat_g1v2.to_sql(
    "px_cat_g1v2",
    schema = "bronze",
    con = engine,
    if_exists = "replace",
    index = False
)