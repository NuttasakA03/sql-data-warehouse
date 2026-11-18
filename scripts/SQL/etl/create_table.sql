CREATE TABLE etl.watermark (
	table_name NVARCHAR(500) PRIMARY KEY,
	last_load DATETIME2 NOT NULL
)

-- Start from original full load, which silver layer already hold
INSERT INTO etl.watermark
SELECT
	'silver.crm_cust_info', 
	MAX(load_date)
FROM bronze.crm_cust_info
WHERE source_file IS NULL

INSERT INTO etl.watermark
SELECT
	'silver.crm_prd_info',
	MAX(load_date)
FROM bronze.crm_prd_info
WHERE source_file IS NULL

INSERT INTO etl.watermark
SELECT
	'silver.crm_sales_details',
	MAX(load_date)
FROM bronze.crm_sales_details
WHERE source_file IS NULL

INSERT INTO etl.watermark
SELECT
	'silver.erp_cust_az12',
	MAX(load_date)
FROM bronze.erp_cust_az12
WHERE source_file IS NULL

INSERT INTO etl.watermark
SELECT
	'silver.erp_loc_a101',
	MAX(load_date)
FROM bronze.erp_loc_a101
WHERE source_file IS NULL

INSERT INTO etl.watermark
SELECT
	'silver.erp_px_cat_g1v2',
	MAX(load_date)
FROM bronze.erp_px_cat_g1v2
WHERE source_file IS NULL