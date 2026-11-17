/*
  =====================================
  Append new data to bronze layer table
  =====================================
  Script Purpose:
  	This script create a temp table to add a new data and insert it into bronze layer table.
  Usage Example:
  	EXEC bronze.append_bronze
*/

-- Create Store Procedure
CREATE OR ALTER PROCEDURE bronze.append_bronze AS
BEGIN
	-- Setup Value for Calculate	
	DECLARE @start_time DATETIME, @end_time DATETIME, @start_whole_time DATETIME, @end_whole_time DATETIME, @cnt INT
	DECLARE @results TABLE (
		table_name sysname,
		rows_inserted INT
	)
	DECLARE @rows_inserted INT = 0
	
	BEGIN TRY
		PRINT '================================='
		PRINT 'APPEND DATA TO BRONZE LAYER TABLE'
		PRINT '================================='
		
		PRINT '================='
		PRINT 'Create Temp Table'
		PRINT '================='
		
		-- Start timer for all process and for each process
		SET @start_whole_time = GETDATE()
		SET @start_time = GETDATE()
		
		PRINT 'Create temp cust_info'
		IF OBJECT_ID('tempdb..#cust_info') IS NOT NULL
			DROP TABLE #cust_info
		CREATE TABLE #cust_info (
			cst_id INT, cst_key NVARCHAR(50), cst_firstname NVARCHAR(50), cst_lastname NVARCHAR(50)
			,cst_marital_status NVARCHAR(50), cst_gndr NVARCHAR(50), cst_create_date DATE
		)
		PRINT 'Successful'
		
		IF OBJECT_ID('tempdb..#prd_info') IS NOT NULL
			DROP TABLE #prd_info
		CREATE TABLE #prd_info (
			prd_id INT, prd_key NVARCHAR(50), prd_nm NVARCHAR(50), prd_cost FLOAT, prd_line NVARCHAR(50), 
			prd_start_dt DATETIME, prd_end_dt DATETIME
		)
		
		IF OBJECT_ID('tempdb..#sales_details') IS NOT NULL
			DROP TABLE #sales_details
		CREATE TABLE #sales_details (
			sls_ord_num NVARCHAR(50), sls_prd_key NVARCHAR(50), sls_cust_id INT, sls_order_dt INT,
			sls_ship_dt INT, sls_due_dt INT, sls_sales FLOAT, sls_quantity INT, sls_price FLOAT
		)
		
		IF OBJECT_ID('tempdb..#cust_az12') IS NOT NULL
			DROP TABLE #cust_az12
		CREATE TABLE #cust_az12 (
			cid NVARCHAR(50), bdate DATE, gen NVARCHAR(50)
		)
		
		IF OBJECT_ID('tempdb..#loc_a101') IS NOT NULL
			DROP TABLE #loc_a101
		CREATE TABLE #loc_a101 (
			cid NVARCHAR(50), cntry NVARCHAR(50)
		)
		
		IF OBJECT_ID('tempdb..#px_cat_g1v2') IS NOT NULL
			DROP TABLE #px_cat_g1v2
		CREATE TABLE #px_cat_g1v2 (
			id NVARCHAR(50), cat NVARCHAR(50), subcat NVARCHAR(50), maintenance NVARCHAR(50)
		)
		
		PRINT 'create temp table successfully'
		
		-- Count only the temp tables this procedure created
		SELECT @cnt =
			  CASE WHEN OBJECT_ID('tempdb..#cust_info') IS NOT NULL THEN 1 ELSE 0 END
			+ CASE WHEN OBJECT_ID('tempdb..#prd_info') IS NOT NULL THEN 1 ELSE 0 END
			+ CASE WHEN OBJECT_ID('tempdb..#sales_details') IS NOT NULL THEN 1 ELSE 0 END
			+ CASE WHEN OBJECT_ID('tempdb..#cust_az12') IS NOT NULL THEN 1 ELSE 0 END
			+ CASE WHEN OBJECT_ID('tempdb..#loc_a101') IS NOT NULL THEN 1 ELSE 0 END
			+ CASE WHEN OBJECT_ID('tempdb..#px_cat_g1v2') IS NOT NULL THEN 1 ELSE 0 END
		
		SET @end_time = GETDATE()
			
		PRINT '>> Create Table Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '>> Create ' + CAST(ISNULL(@cnt, 0) AS NVARCHAR) + ' Temp Table'
		
		-- Insert new data into temp table
		
		PRINT '==============================='
		PRINT 'Start Load data into temp table'
		PRINT '==============================='
		
		SET @start_time = GETDATE()
		
		PRINT 'Insert cust_info to temp table'
		PRINT '--------------------------------'
		
		BULK INSERT #cust_info
		FROM '/tmp/datasets/incremental/batch_01/source_crm/cust_info.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',', 
			TABLOCK
		)
		
		SET @rows_inserted = @@ROWCOUNT
		SET @end_time = GETDATE()
		
		INSERT INTO @results VALUES ('cust_info', @rows_inserted)
		
		PRINT '>> Inserted Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '>> Inserted: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'	
		
		PRINT '--------------------------------'
		PRINT 'Insert prd_info into temp table'
		PRINT '--------------------------------'
		
		SET @start_time = GETDATE()
	
		BULK INSERT #prd_info
		FROM '/tmp/datasets/incremental/batch_01/source_crm/prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		
		--Count the output into append_results
		SET @rows_inserted = @@ROWCOUNT
		SET @end_time = GETDATE()
		
		INSERT INTO @results VALUES ('prd_info', @rows_inserted)
		
		PRINT '>> Inserted Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '>> Inserted: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		
		PRINT '------------------------------------'
		PRINT 'Insert sales_details into temp table'
		PRINT '------------------------------------'
		
		SET @start_time = GETDATE()
			
		BULK INSERT #sales_details
		FROM '/tmp/datasets/incremental/batch_01/source_crm/sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		
		--Count the output into append_results
		SET @rows_inserted = @@ROWCOUNT
		SET @end_time = GETDATE()
		
		INSERT INTO @results VALUES ('sales_details', @rows_inserted)
		
		PRINT '>> Inserted Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '>> Inserted: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		
		PRINT '--------------------------------'
		PRINT 'Insert cust_az12 into temp table'
		PRINT '--------------------------------'
	
		SET @start_time = GETDATE()
		
		BULK INSERT #cust_az12
		FROM '/tmp/datasets/incremental/batch_01/source_erp/CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		
		SET @rows_inserted = @@ROWCOUNT
		SET @end_time = GETDATE()
		
		INSERT INTO @results VALUES ('cust_az12', @rows_inserted)
		
		PRINT '>> Inserted Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '>> Inserted: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		
		PRINT '-------------------------------'
		PRINT 'Insert loc_a101 into temp table'
		PRINT '-------------------------------'
		
		SET @start_time = GETDATE()
		
		BULK INSERT #loc_a101
		FROM '/tmp/datasets/incremental/batch_01/source_erp/LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		
		SET @rows_inserted = @@ROWCOUNT
		SET @end_time = GETDATE()
		
		INSERT INTO @results VALUES ('loc_a101', @rows_inserted)
		
		PRINT '>> Inserted Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '>> Inserted: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		
		PRINT '----------------------------------'
		PRINT 'Insert px_cat_g1v2 into temp table'
		PRINT '----------------------------------'
		
		SET @start_time = GETDATE()
		
		BULK INSERT #px_cat_g1v2
		FROM '/tmp/datasets/incremental/batch_01/source_erp/PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		
		--Count the output into append_results
		SET @rows_inserted = @@ROWCOUNT
		SET @end_time = GETDATE()
		
		INSERT INTO @results VALUES ('px_cat_g1v2', @rows_inserted)
		
		PRINT '>> Inserted Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '>> Inserted: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		
		-- Insert data from temp table into bronze layer table
		
		PRINT '================================================='
		PRINT 'INSERT DATA FROM TEMP TABLE TO BRONZE LAYER TABLE'
		PRINT '================================================='
		
		PRINT 'Insert data into bronze.crm_cust_info'
		print '-------------------------------------'
		
		SET @start_time = GETDATE()
		
		INSERT INTO bronze.crm_cust_info (
				cst_id,
				cst_key,
				cst_firstname,
				cst_lastname,
				cst_marital_status,
				cst_gndr,
				cst_create_date,
				source_file
			)
			
		SELECT 
			*,
			'batch_01/source_crm/cust_info.csv'
		FROM #cust_info
		
		--Count the output into append_results
		SET @rows_inserted = @@ROWCOUNT
		SET @end_time = GETDATE()
		
		INSERT INTO @results VALUES ('cust_info', @rows_inserted)
		
		PRINT '>> Inserted Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '>> Inserted: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		
		PRINT '------------------------------------'
		PRINT 'Insert data into bronze.crm_prd_info'
		print '------------------------------------'
		
		SET @start_time = GETDATE()
		
		INSERT INTO bronze.crm_prd_info (
			prd_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt,
			source_file
		)
		SELECT
			*,
			'batch_01/source_crm/prd_info.csv'
		FROM #prd_info
		
		SET @rows_inserted = @@ROWCOUNT
		SET @end_time = GETDATE()
		
		INSERT INTO @results VALUES ('prd_info', @rows_inserted)
		
		PRINT '>> Inserted Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '>> Inserted: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		
		PRINT '-----------------------------------------'
		PRINT 'Insert data into bronze.crm_sales_details'
		print '-----------------------------------------'
		
		SET @start_time = GETDATE()
		
		
		INSERT INTO bronze.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price,
			source_file
		)
		SELECT 
			*,
			'batch_01/source_crm/sales_details.csv'
		FROM #sales_details
		
		SET @rows_inserted = @@ROWCOUNT
		SET @end_time = GETDATE()
		
		INSERT INTO @results VALUES ('sales_details', @rows_inserted)
		
		PRINT '>> Inserted Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '>> Inserted: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		
		PRINT '-------------------------------------'
		PRINT 'Insert data into bronze.erp_cust_az12'
		print '-------------------------------------'
		
		SET @start_time = GETDATE()
		
		INSERT INTO bronze.erp_cust_az12 (
			cid,
			bdate,
			gen,
			source_file
		)
		
		SELECT 
			*,
			'batch_01/source_erp/CUST_AZ12.csv'
		FROM #cust_az12
		
		--Count the output into append_results
		SET @rows_inserted = @@ROWCOUNT
		SET @end_time = GETDATE() 
		
		INSERT INTO @results VALUES ('cust_az12', @rows_inserted)
		
		PRINT '>> Inserted Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '>> Inserted: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		
		PRINT '-------------------------------------'
		PRINT 'Insert data into bronze.erp_loc_a101'
		print '-------------------------------------'
		
		SET @start_time = GETDATE()
		
		INSERT INTO bronze.erp_loc_a101 (
			cid,
			cntry,
			source_file
		)
		
		SELECT 
			*,
			'batch_01/source_erp/LOC_A101.csv'
		FROM #loc_a101
		
		--Count the output into append_results
		SET @rows_inserted = @@ROWCOUNT
		SET @end_time = GETDATE()
		
		INSERT INTO @results VALUES ('loc_a101', @rows_inserted)
		
		PRINT '>> Inserted Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '>> Inserted: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		
		PRINT '-------------------------------------'
		PRINT 'Insert data into bronze.erp_px_cat_g1v2'
		print '-------------------------------------'
		
		SET @start_time = GETDATE()
		
		INSERT INTO bronze.erp_px_cat_g1v2 (
			id,
			cat,
			subcat,
			maintenance,
			source_file
		)
		
		SELECT 
			*,
			'batch_01/source_erp/PX_CAT_G1V2.csv'
		FROM #px_cat_g1v2
		
		--Count the output into append_results
		SET @rows_inserted = @@ROWCOUNT
		SET @end_time = GETDATE()
		
		INSERT INTO @results VALUES ('px_cat_g1v2', @rows_inserted)
		
		PRINT '>> Inserted Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '>> Inserted: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		
			
		-- DROP Temp Table
		DROP TABLE #cust_info
		DROP TABLE #prd_info
		DROP TABLE #sales_details
		DROP TABLE #cust_az12
		DROP TABLE #loc_a101
		DROP TABLE #px_cat_g1v2
		
		SET @end_whole_time = GETDATE()
		
		PRINT '========================================'
		PRINT 'All Durations: ' + CAST(DATEDIFF(SECOND, @start_whole_time, @end_whole_time) AS NVARCHAR)
		PRINT '========================================'
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================';
        PRINT 'ERROR OCCURRED DURING APPEND';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT '=========================================';
	END CATCH
END
