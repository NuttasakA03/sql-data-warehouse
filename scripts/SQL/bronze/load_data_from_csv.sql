/*
========================================
LOADED CSV FILE IN TABLE IN BRONZE LAYER
========================================
Scripts purpose: 
	this script going to create store procedures to loaded data from csv in each table that prepared.
	If data exists, It will deleted and reloaded. The script loaded six data from different place
	in each six tables we had created
Usage Example:
	EXEC bronze.load_bronze
WARNING: 
	This script will deleted all data in tables.
	Make sure you have backups before running this script
*/

-- Create or Alter store procedures
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @whole_start_time DATETIME, @whole_end_time DATETIME
	BEGIN TRY
		PRINT '===================='
		PRINT 'Loading Bronze Layer'
		PRINT '===================='
	
		PRINT '------------------'
		PRINT 'Loading CRM Tables'
		PRINT '------------------'

		-- Loaded cust_info.csv into bronze.crm_cust_info tables
		SET @start_time = GETDATE()
		SET @whole_start_time = GETDATE()
		PRINT '>> Trucating Table: bronze.crm_cust_info'
		TRUNCATE TABLE bronze.crm_cust_info

		PRINT '>> Inserting Data Into Table: bronze.crm_cust_info'
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\work\DataEngineer\sql-data-warehouse\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '------------------------'

		-- Loaded prd_info.csv into bronze.crm_prd_info tables 
		SET @start_time = GETDATE()
		PRINT '>> Trucating Table: bronze.crm_prd_info'
		TRUNCATE TABLE bronze.crm_prd_info

		PRINT '>> Inserting Data Into Table: bronze.crm_prd_info'
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\work\DataEngineer\sql-data-warehouse\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '------------------------'
		

		-- Loaded sales_details.csv into bronze.crm_sales_details tables 
		SET @start_time = GETDATE()
		PRINT '>> Trucating Table: bronze.crm_sales_details'
		TRUNCATE TABLE bronze.crm_sales_details

		PRINT '>> Inserting Data Into Table: bronze.crm_sales_details'
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\work\DataEngineer\sql-data-warehouse\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '------------------------'

		PRINT '------------------'
		PRINT 'Loading ERP Tables'
		PRINT '------------------'

		-- Loaded CUST_AZ12.csv into bronze.erp_cust_az12 tables 
		SET @start_time = GETDATE()
		PRINT '>> Trucating Table: bronze.erp_cust_az12'
		TRUNCATE TABLE bronze.erp_cust_az12

		PRINT '>> Inserting Data Into Table: bronze.erp_cust_az12'
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\work\DataEngineer\sql-data-warehouse\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '------------------------'

		-- Loaded LOC_A101.csv into bronze.erp_loc_a101 tables 
		SET @start_time = GETDATE()
		PRINT '>> Trucating Table: bronze.erp_loc_a101'
		TRUNCATE TABLE bronze.erp_loc_a101

		PRINT '>> Inserting Data Into Table: bronze.erp_loc_a101'
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\work\DataEngineer\sql-data-warehouse\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '------------------------'

		-- Loaded PX_CAT_G1V2.csv into bronze.erp_px_cat_g1v2 tables 
		SET @start_time = GETDATE()
		PRINT '>> Trucating Table: erp_px_cat_g1v2'
		TRUNCATE TABLE bronze.erp_px_cat_g1v2

		PRINT '>> Inserting Data Into Table: bronze.erp_px_cat_g1v2'
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\work\DataEngineer\sql-data-warehouse\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		SET @end_time = GETDATE()
		SET @whole_end_time = GETDATE()
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '------------------------'

		PRINT '================================='
		PRINT 'Loading Bronze Layer is Completed'
		PRINT '	- Whole Process Duration: ' + CAST(DATEDIFF(second, @whole_start_time, @whole_end_time) AS NVARCHAR) + ' second'
		PRINT '================================='

	END TRY
	BEGIN CATCH
		PRINT '========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Number' + CAST(ERROR_NUMBER() AS NVARCHAR)
		PRINT 'Error State' + CAST(ERROR_STATE() AS NVARCHAR)
		PRINT '========================================='
	END CATCH
END