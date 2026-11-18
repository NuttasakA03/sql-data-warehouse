CREATE OR ALTER PROCEDURE silver.merge_silver AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @new_wm DATETIME2 = (SELECT MAX(load_date) FROM bronze.crm_cust_info)
		DECLARE @wm DATETIME2 = (SELECT last_load FROM etl.watermark WHERE table_name = 'silver.crm_cust_info')
		DECLARE @start_time DATETIME2, @end_time DATETIME2, @rows_changed INT 
		DECLARE @results TABLE (
			table_name sysname,
			rows_inserted INT
		)
		DECLARE @rows_inserted INT = 0
		
		PRINT '================================================'
		PRINT 'Transform and merge data into silver layer table'
		PRINT '================================================'
		
		PRINT 'Transform and Merge cust_info'
		PRINT '-----------------------------'
		
		SET @start_time = GETDATE()
		
		;WITH sub1 AS (
			SELECT 
				cst_id,
				cst_key,
				TRIM(cst_firstname) AS cst_firstname,
				TRIM(cst_lastname) AS cst_lastname,
				CASE 
					WHEN TRIM(UPPER(cst_marital_status)) = 'M' THEN 'Married'
					WHEN TRIM(UPPER(cst_marital_status)) = 'S' THEN 'Single'
					ELSE 'n/a'
				END AS cst_marital_status,
				CASE
					WHEN TRIM(UPPER(cst_gndr)) = 'M' THEN 'Male'
					WHEN TRIM(UPPER(cst_gndr)) = 'F' THEN 'Female'
					ELSE 'n/a'
				END AS cst_gndr,
				cst_create_date,
				ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC, load_date DESC)AS rn
			FROM bronze.crm_cust_info
			WHERE load_date > @wm AND cst_id IS NOT NULL
		)
		
		MERGE silver.crm_cust_info AS t
		USING (SELECT * FROM sub1 WHERE rn = 1) AS s
			ON t.cst_id = s.cst_id
		WHEN MATCHED AND (
			ISNULL(t.cst_firstname, '') != ISNULL(s.cst_firstname, '')
			OR ISNULL(t.cst_lastname, '') != ISNULL(s.cst_lastname, '')
			OR ISNULL(t.cst_marital_status, '') != ISNULL(s.cst_marital_status, '')
			OR ISNULL(t.cst_gndr, '') != ISNULL(s.cst_gndr, '')
			OR t.cst_create_date != s.cst_create_date
		)
		THEN UPDATE SET
			t.cst_firstname = s.cst_firstname,
			t.cst_lastname = s.cst_lastname,
			t.cst_marital_status = s.cst_marital_status,
			t.cst_gndr = s.cst_gndr,
			t.cst_create_date = s.cst_create_date
		WHEN NOT MATCHED BY TARGET THEN
			INSERT(
				cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date
			)
			VALUES (
				s.cst_id, s.cst_key, s.cst_firstname, s.cst_lastname, s.cst_marital_status, s.cst_gndr, s.cst_create_date
			);
		SET @rows_inserted = @@ROWCOUNT
		
		INSERT INTO @results VALUES('cust_info', @rows_inserted)
	
		UPDATE etl.watermark 
			SET last_load = @new_wm WHERE table_name = 'silver.crm_cust_info';
		
		SET @end_time = GETDATE()
		
		PRINT 'Updated: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '================================='
		
		PRINT 'Transform and Merge prd_info'
		PRINT '-----------------------------'
		
		SET @wm = (SELECT last_load FROM etl.watermark WHERE table_name = 'silver.crm_prd_info')
		SET @new_wm = (SELECT MAX(load_date) FROM bronze.crm_prd_info)
		SET @start_time = GETDATE()
		
		;WITH sub2 AS (
			SELECT 
				prd_id,
				REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
				SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
				prd_nm,
				COALESCE(prd_cost, 0) AS prd_cost,
				CASE TRIM(UPPER(prd_line))
					WHEN 'M' THEN 'Mountain'
					WHEN 'R' THEN 'Road'
					WHEN 'S' THEN 'Other Sales'
					WHEN 'T' THEN 'Touring'
				END AS prd_line,
				CAST(prd_start_dt AS DATE) AS prd_start_dt
			FROM bronze.crm_prd_info
			WHERE load_date > @wm AND prd_id IS NOT NULL
		)
		
		MERGE silver.crm_prd_info AS t
		USING (SELECT * FROM sub2) AS s
			ON t.prd_id = s.prd_id
		WHEN MATCHED AND (
			ISNULL(t.prd_key, '') != ISNULL(s.prd_key, '')
			OR ISNULL(t.cat_id, '') != ISNULL(s.cat_id, '')
			OR ISNULL(t.prd_nm, '') != ISNULL(s.prd_nm, '')
			OR ISNULL(t.prd_cost, '') != ISNULL(s.prd_cost, '')
			OR ISNULL(t.prd_line, '') != ISNULL(s.prd_line, '')
			OR ISNULL(t.prd_start_dt, '') != ISNULL(s.prd_start_dt, '')
		)
		THEN UPDATE SET
			t.prd_key = s.prd_key,
			t.cat_id = s.cat_id,
			t.prd_nm = s.prd_nm,
			t.prd_cost = s.prd_cost,
			t.prd_line = s.prd_line,
			t.prd_start_dt = s.prd_start_dt
		WHEN NOT MATCHED BY TARGET THEN
			INSERT(
				prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt
			)
			VALUES (
				s.prd_id, s.cat_id, s.prd_key, s.prd_nm, s.prd_cost, s.prd_line, s.prd_start_dt
			);

		SET @rows_inserted = @@ROWCOUNT		
		INSERT INTO @results VALUES('prd_info', @rows_inserted)
		
		;WITH changed_keys AS (
			SELECT 
				DISTINCT SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key
			FROM bronze.crm_prd_info
			WHERE load_date > @wm
		),
		new_end AS (
			SELECT
				p.prd_key,
				CAST(DATEADD(DAY, -1, LEAD(p.prd_start_dt) OVER(PARTITION BY p.prd_key ORDER BY p.prd_start_dt)) AS DATE) AS new_end_dt
			FROM silver.crm_prd_info AS p
			WHERE p.prd_key IN (SELECT prd_key FROM changed_keys)
		)
		
		UPDATE p SET
			p.prd_end_dt = n.new_end_dt
		FROM silver.crm_prd_info AS p
		JOIN new_end AS n
			ON p.prd_key = n.prd_key
		WHERE ISNULL(p.prd_end_dt, '9999-12-31') != ISNULL(n.new_end_dt, '9999-12-31')
	
		UPDATE etl.watermark 
			SET last_load = @new_wm WHERE table_name = 'silver.crm_prd_info';
		
		SET @end_time = GETDATE()
		
		PRINT 'Updated: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '================================='

		PRINT 'Transform and Merge sales_details'
		PRINT '---------------------------------'
		
		SET @start_time = GETDATE()
		SET @wm = (SELECT last_load FROM etl.watermark WHERE table_name = 'silver.crm_sales_details')
		SET @new_wm = (SELECT MAX(load_date) FROM bronze.crm_sales_details)
		
		;WITH sub3 AS (
			SELECT 
				sls_ord_num,
				sls_prd_key,
				sls_cust_id,
				CASE 
					WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
					ELSE CAST(
						CAST(sls_order_dt AS NVARCHAR) AS DATE
					)
				END AS sls_order_dt,
				CASE
					WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
					ELSE CAST(
						CAST(sls_ship_dt AS NVARCHAR) AS DATE
					)
				END AS sls_ship_dt,
				CASE 
					WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
					ELSE CAST (
						CAST(sls_due_dt AS NVARCHAR) AS DATE
					)
				END AS sls_due_dt,
				CASE 
					WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
						THEN sls_quantity * ABS(sls_price)
					ELSE sls_sales
				END AS sls_sales,
				sls_quantity,
				CASE 
					WHEN sls_price IS NULL OR sls_price <= 0
						THEN sls_sales / NULLIF(sls_quantity, 0)
					ELSE sls_price
				END AS sls_price
			FROM bronze.crm_sales_details 
			WHERE load_date > @wm AND sls_ord_num IS NOT NULL
		)
		
		MERGE silver.crm_sales_details AS t
		USING (SELECT * FROM sub3) AS s
			ON t.sls_ord_number = s.sls_ord_num 
			AND t.sls_prd_key = s.sls_prd_key
			AND t.sls_cust_id = s.sls_cust_id
			WHEN MATCHED AND
				ISNULL(t.sls_prd_key, '') != ISNULL(s.sls_prd_key, '')
				OR ISNULL(t.sls_cust_id, '') != ISNULL(s.sls_cust_id, '')
				OR ISNULL(t.sls_order_dt, '') != ISNULL(s.sls_order_dt, '')
				OR ISNULL(t.sls_ship_dt, '') != ISNULL(s.sls_ship_dt, '')
				OR ISNULL(t.sls_due_dt, '') != ISNULL(s.sls_due_dt, '')
				OR ISNULL(t.sls_sales, '') != ISNULL(s.sls_sales, '')
				OR ISNULL(t.sls_quantity, '') != ISNULL(s.sls_quantity, '')
				OR ISNULL(t.sls_price, '') != ISNULL(s.sls_price, '')
			THEN UPDATE SET
				t.sls_prd_key = s.sls_prd_key,
				t.sls_cust_id = s.sls_cust_id,
				t.sls_order_dt = s.sls_order_dt,
				t.sls_ship_dt = s.sls_ship_dt,
				t.sls_due_dt = s.sls_due_dt,
				t.sls_sales = s.sls_sales,
				t.sls_quantity = s.sls_quantity,
				t.sls_price = s.sls_price
			WHEN NOT MATCHED BY TARGET THEN
			INSERT (sls_ord_number, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
			VALUES (s.sls_ord_num, s.sls_prd_key, s.sls_cust_id, s.sls_order_dt, s.sls_ship_dt, s.sls_due_dt, s.sls_sales, s.sls_quantity, s.sls_price);

		SET @rows_inserted = @@ROWCOUNT
		INSERT INTO @results VALUES ('sales_details', @rows_inserted)
		
		UPDATE etl.watermark SET
			last_load = @new_wm 
		WHERE table_name = 'silver.crm_sales_details'
		
		SET @end_time = GETDATE()
		
		PRINT 'Updated: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '================================='
		
		PRINT 'Transform and Merge cust_az12'
		PRINT '-----------------------------'
		
		SET @start_time = GETDATE()
		SET @wm = (SELECT last_load FROM etl.watermark WHERE table_name = 'silver.erp_cust_az12')
		SET @new_wm = (SELECT MAX(load_date) FROM bronze.erp_cust_az12)
		
		;WITH sub4 AS (
			SELECT 
				CASE 
					WHEN cid LIKE '%NAS' THEN SUBSTRING(cid, 4, LEN(cid))
					ELSE cid
				END AS cid,
				CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END AS bdate,
				CASE 
					WHEN TRIM(UPPER(gen)) IN ('F', 'FEMALE') THEN 'Female'
					WHEN TRIM(UPPER(gen)) IN ('M', 'MALE') THEN 'Male'
					ELSE 'n/a'
				END AS gen
			FROM bronze.erp_cust_az12
			WHERE load_date > @wm AND cid IS NOT NULL
		)
		
		MERGE silver.erp_cust_az12 AS t
		USING (SELECT * FROM sub4) AS s
			ON t.cid = s.cid
		WHEN MATCHED AND 
			ISNULL(t.bdate, '') != ISNULL(s.bdate, '')
			OR ISNULL(t.gndr, '') != ISNULL(s.gen, '')
		THEN UPDATE SET
			t.bdate = s.bdate,
			t.gndr = s.gen
		WHEN NOT MATCHED BY TARGET THEN
		INSERT (cid, bdate, gndr)
		VALUES (s.cid, s.bdate, s.gen);

		SET @rows_inserted = @@ROWCOUNT
		INSERT INTO @results VALUES ('cust_az12', @rows_inserted)
		
		UPDATE etl.watermark SET
			last_load = @new_wm
		WHERE table_name = 'silver.erp_cust_az12'
		
		SET @end_time = GETDATE()
		
		PRINT 'Updated: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '================================='
		
		PRINT 'Transform and Merge loc_a101'
		PRINT '----------------------------'
		
		SET @start_time = GETDATE()
		SET @wm = (SELECT last_load FROM etl.watermark WHERE table_name = 'silver.erp_loc_a101')
		SET @new_wm = (SELECT MAX(load_date) FROM bronze.erp_loc_a101)
		
		;WITH sub5 AS (
			SELECT 	
				REPLACE(cid, '-', '') AS cid,
				CASE 
					WHEN TRIM(cntry) IN ('USA', 'US', 'United States') THEN 'United States'
					WHEN TRIM(cntry) IN ('DE', 'Germany') THEN 'Germany'
					WHEN TRIM(cntry) IN (NULL, '') THEN 'n/a'
					ELSE cntry
				END AS cntry,
				ROW_NUMBER() OVER(PARTITION BY cid ORDER BY load_date DESC) AS rn
			FROM bronze.erp_loc_a101
			WHERE load_date > @wm AND cid IS NOT NULL
		)
		
		MERGE silver.erp_loc_a101 AS t
		USING (SELECT * FROM sub5 WHERE rn = 1) AS s
			ON t.cid = s.cid
		WHEN MATCHED AND 
			ISNULL(t.cntry, '') != ISNULL(s.cntry, '')
		THEN UPDATE SET
			t.cntry = s.cntry
		WHEN NOT MATCHED BY TARGET THEN
		INSERT (cid, cntry)
		VALUES (s.cid, s.cntry);

		SET @rows_inserted = @@ROWCOUNT
		INSERT INTO @results VALUES ('loc_a101', @rows_inserted)
		
		UPDATE etl.watermark SET
			last_load = @new_wm
		WHERE table_name = 'silver.erp_loc_a101'
		
		SET @end_time = GETDATE()
		
		PRINT 'Updated: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '================================='
		
		PRINT 'Transform and Merge px_cat_g1v2'
		PRINT '-------------------------------'
		
		SET @start_time = GETDATE()
		SET @wm = (SELECT last_load FROM etl.watermark WHERE table_name = 'silver.erp_px_cat_g1v2')
		SET @new_wm = (SELECT MAX(load_date) FROM bronze.erp_px_cat_g1v2)
		
		;WITH sub6 AS (
			SELECT
				id, cat, subcat, maintenance
			FROM bronze.erp_px_cat_g1v2
			WHERE load_date > @wm AND id IS NOT NULL
		)
		
		MERGE silver.erp_px_cat_g1v2 AS t
		USING (SELECT * FROM sub6) AS s
			ON t.id = s.id
		WHEN MATCHED AND
			ISNULL(t.cat, '') != ISNULL(s.cat, '')
			OR ISNULL(t.subcat, '') != ISNULL(s.subcat, '')
			OR ISNULL(t.maintenance, '') != ISNULL(s.maintenance, '')
		THEN UPDATE SET
			t.cat = s.cat,
			t.subcat = s.subcat,
			t.maintenance = s.maintenance
		WHEN NOT MATCHED BY TARGET THEN
		INSERT (id, cat, subcat, maintenance)
		VALUES (s.id, s.cat, s.subcat, s.maintenance);

		SET @rows_inserted = @@ROWCOUNT
		INSERT INTO @results VALUES ('px_cat_g1v2', @rows_inserted)
		
		UPDATE etl.watermark SET
			last_load = @new_wm
		WHERE table_name = 'silver.erp_px_cat_g1v2'
		
		SET @end_time = GETDATE()
		
		PRINT 'Updated: ' + CAST(@rows_inserted AS NVARCHAR) + ' Rows'
		PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds'
		PRINT '================================='
		
		SET @rows_changed = (SELECT SUM(rows_inserted) FROM @results)
		PRINT 'All Updated: ' + CAST(@rows_changed AS NVARCHAR) + ' Rows'
	END TRY
	BEGIN CATCH
		PRINT '=========================================';
        PRINT 'ERROR OCCURRED DURING MERGE';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT '=========================================';
		THROW
	END CATCH
END

