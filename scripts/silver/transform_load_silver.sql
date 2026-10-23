/*
============================================================
TRANSFORMATION AND LOAD DATA IN BRONZE LAYER TO SILVER LAYER
============================================================
Scripts purpose: 
	this script going to create store procedures to transform data from bronze layer to silver layer.
	If data exists, It will deleted and reloaded. The script loaded data from bronze layer in each six tables we had created
Usage Example:
	EXEC silver.transform_load_silver
WARNING: 
	This script will deleted all data in tables.
	Make sure you have backups before running this script
*/

-- Create or Alter store procedures
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @whole_start_time DATETIME, @whole_end_time DATETIME
	BEGIN TRY
		PRINT '===================='
		PRINT 'Loading Silver Layer'
		PRINT '===================='
	
		PRINT '------------------'
		PRINT 'Loading CRM Tables'
		PRINT '------------------'

		-- Transform and load bronze.crm_cust_info to silver.crm_cust_info
		SET @start_time = GETDATE()
		SET @whole_start_time = GETDATE()
		PRINT '>> Trucating Table: silver.crm_cust_info'
		TRUNCATE TABLE silver.crm_cust_info

		PRINT '>> Inserting Data Into Table: silver.crm_cust_info';
		;WITH sub1 AS (
			SELECT
				*,
				RANK() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) flag_last
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		)

		INSERT INTO silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)
		SELECT
			cst_id,
			cst_key,
			TRIM(cst_firstname) cst_firstname,
			TRIM(cst_lastname) cst_lastname,
			CASE 
				WHEN UPPER(cst_material_status) = 'S' THEN 'Single' 
				WHEN UPPER(cst_material_status) = 'M' THEN 'Married' 
				ELSE 'n/a'
			END cst_marital_status,
			CASE 
				WHEN UPPER(cst_gndr) = 'F' THEN 'Female' 
				WHEN UPPER(cst_gndr) = 'M' THEN 'Male' 
				ELSE 'n/a'
			END cst_gndr,
			cst_create_date
		FROM sub1
		WHERE flag_last = 1;
	
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '------------------------'

		-- Transform and load bronze.crm_prd_info to silver.crm_prd_info
		SET @start_time = GETDATE()
		PRINT '>> Trucating Table: silver.crm_prd_info'
		TRUNCATE TABLE silver.crm_prd_info

		PRINT '>> Inserting Data Into Table: silver.crm_prd_info'
		INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)

		SELECT
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') cat_id,
			SUBSTRING(prd_key, 7, LEN(prd_key)) prd_key,
			prd_nm,
			COALESCE(prd_cost, 0) prd_cost,
			CASE UPPER(prd_line)
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				ELSE 'n/a'
			END prd_line,
			CAST(prd_start_dt AS DATE) prd_start_dt,
			CAST(
				LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE	
			) prd_end_dt
		FROM bronze.crm_prd_info

		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '------------------------'
		

		-- Transform and load bronze.crm_sales_details to silver.crm_sales_details
		SET @start_time = GETDATE()
		PRINT '>> Trucating Table: silver.crm_sales_details'
		TRUNCATE TABLE silver.crm_sales_details

		PRINT '>> Inserting Data Into Table: silver.crm_sales_details'
		INSERT INTO silver.crm_sales_details (
			sls_ord_number,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)

		SELECT
			sls_ord_number,
			sls_prd_key,
			sls_cust_id,
			CASE
				WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
				ELSE CAST(
						CAST(sls_order_dt AS VARCHAR) AS DATE
					)
			END sls_order_dt,
			CASE
				WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				ELSE CAST(
						CAST(sls_ship_dt AS VARCHAR) AS DATE
					)
			END sls_ship_dt,
			CASE
				WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
				ELSE CAST(
						CAST(sls_due_dt AS VARCHAR) AS DATE
					)
			END sls_due_dt,
			CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
					THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
			END sls_sales,
			sls_quantity,
			CASE WHEN sls_price IS NULL OR sls_price <= 0 
					THEN sls_sales/ NULLIF(sls_quantity, 0)
				ELSE sls_price
			END sls_price
		FROM bronze.crm_sales_details

		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '------------------------'

		PRINT '------------------'
		PRINT 'Loading ERP Tables'
		PRINT '------------------'

		-- Transform and load bronze.erp_cust_az12 to silver.erp_cust_az12
		SET @start_time = GETDATE()
		PRINT '>> Trucating Table: silver.erp_cust_az12'
		TRUNCATE TABLE silver.erp_cust_az12

		PRINT '>> Inserting Data Into Table: silver.erp_cust_az12'
		INSERT INTO silver.erp_cust_az12 (
			cid, bdate, gndr
		)

		SELECT
			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END cid,
			CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END bdate,
			CASE 
				WHEN UPPER(TRIM(gndr)) IN ('F', 'Female') THEN 'Female'
				WHEN UPPER(TRIM(gndr)) IN ('M', 'Male') THEN 'Male'
				ELSE 'n/a'
			END gndr
		FROM bronze.erp_cust_az12

		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '------------------------'

		-- Transform and load bronze.erp_loc_a101 to silver.erp_loc_a101
		SET @start_time = GETDATE()
		PRINT '>> Trucating Table: silver.erp_loc_a101'
		TRUNCATE TABLE silver.erp_loc_a101

		PRINT '>> Inserting Data Into Table: silver.erp_loc_a101'
		INSERT INTO silver.erp_loc_a101 (cid, cntry)

		SELECT
			REPLACE(cid, '-', '') cid,
			CASE 
				WHEN TRIM(cntry) IN ('USA', 'US', 'United States') THEN 'United States'
				WHEN TRIM(cntry) IN ('DE', 'Germany') THEN 'Germany'
				WHEN TRIM(cntry) IN (NULL, '') THEN 'n/a'
				ELSE cntry
			END cntry
		FROM bronze.erp_loc_a101

		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '------------------------'

		-- Transform and load bronze.erp_px_cat_g1v2 to silver.erp_px_cat_g1v2
		SET @start_time = GETDATE()
		PRINT '>> Trucating Table: silver.erp_px_cat_g1v2'
		TRUNCATE TABLE silver.erp_px_cat_g1v2

		PRINT '>> Inserting Data Into Table: silver.erp_px_cat_g1v2'
		INSERT INTO silver.erp_px_cat_g1v2 (
			id, cat, subcat, maintenance
		)

		SELECT
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2

		SET @end_time = GETDATE()
		SET @whole_end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '------------------------'

		PRINT '================================='
		PRINT 'Loading Silver Layer is Completed'
		PRINT '	- Whole Process Duration: ' + CAST(DATEDIFF(second, @whole_start_time, @whole_end_time) AS NVARCHAR) + ' second'
		PRINT '================================='

	END TRY
	BEGIN CATCH
		PRINT '========================================='
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Number' + CAST(ERROR_NUMBER() AS NVARCHAR)
		PRINT 'Error State' + CAST(ERROR_STATE() AS NVARCHAR)
		PRINT '========================================='
	END CATCH
END