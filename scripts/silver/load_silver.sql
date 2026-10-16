/*
===============================================================================
Script: Load Silver Layer (Bronze -> Silver)
===============================================================================
Purpose:
    Cleans and standardizes the raw data in the Bronze layer and loads it into
    the Silver layer of the data warehouse. Prints how long each table load
    and the whole run take.

Silver Layer:
    The second layer of the Medallion Architecture (Bronze, Silver, Gold).
    It stores cleaned, standardized and de-duplicated data, ready for
    modelling in the Gold layer.

Load Type:
    Full load. Each table is emptied and reloaded on every run, so the
    Silver layer always mirrors the current Bronze layer and reruns never
    create duplicates. The load is wrapped in a stored procedure, so the
    whole Silver layer can be refreshed with a single command:
        EXEC silver.load_silver;

WARNING:
    Running this procedure deletes all existing rows in the six silver tables
    before reloading them.
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

    -- Timers for each table load and for the whole run
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        PRINT '========================================================================';
        PRINT 'Loading the Silver Layer';
        PRINT '========================================================================';

        -- ------------------------------------------------------------
        -- Loading CRM Tables
        -- ------------------------------------------------------------
        PRINT '----------------------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '----------------------------------------------------------------';

        -- Each table follows the same steps: truncate, clean and insert, print duration

        -- ------------------------------------------------------------
        -- Table:   silver.crm_cust_info
        -- Purpose: Clean and load CRM customer details into the Silver layer.
        -- ------------------------------------------------------------
        -- Removes records with no customer ID, keeps only the latest record per
        -- customer, trims names, and standardizes marital status and gender codes
        -- into readable values ('n/a' / 'Unknown' when missing).
        -- ------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        PRINT '>> Inserting Data Into: silver.crm_cust_info';
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
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname)  AS cst_lastname,
            CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                 WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                 ELSE 'n/a'
            END AS cst_marital_status,
            CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                 ELSE 'Unknown'
            END AS cst_gndr,
            cst_create_date
        FROM (
            SELECT
                *,
                ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t
        WHERE flag_last = 1; -- Latest record per customer
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- ------------------------------------------------------------
        -- Table:   silver.crm_prd_info
        -- Purpose: Clean and load CRM product details into the Silver layer.
        -- ------------------------------------------------------------
        -- Splits prd_key into a category ID and a product key, replaces missing costs
        -- with 0, maps product line codes to descriptive names, and derives each
        -- product's end date from the next start date.
        -- ------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        PRINT '>> Inserting Data Into: silver.crm_prd_info';
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
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- Matches the 'id' format in erp_px_cat_g1v2
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,        -- Matches the product key in the sales table
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt -- Day before the next start date
        FROM bronze.crm_prd_info;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- ------------------------------------------------------------
        -- Table:   silver.crm_sales_details
        -- Purpose: Clean and load CRM sales transactions into the Silver layer.
        -- ------------------------------------------------------------
        -- Converts integer dates (YYYYMMDD) to DATE, setting invalid ones to NULL,
        -- and recalculates sales and price when the original values are missing,
        -- non-positive or inconsistent with quantity.
        -- ------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;

        PRINT '>> Inserting Data Into: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_ord_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE WHEN sls_ord_dt = 0 OR LEN(sls_ord_dt) != 8 THEN NULL
                 ELSE CAST(CAST(sls_ord_dt AS VARCHAR(50)) AS DATE) -- Integer must go through VARCHAR to become a DATE
            END AS sls_ord_dt,
            CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                 ELSE CAST(CAST(sls_ship_dt AS VARCHAR(50)) AS DATE)
            END AS sls_ship_dt,
            CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                 ELSE CAST(CAST(sls_due_dt AS VARCHAR(50)) AS DATE)
            END AS sls_due_dt,
            CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
                 THEN sls_quantity * ABS(sls_price)
                 ELSE sls_sales
            END AS sls_sales,
            sls_quantity,
            CASE WHEN sls_price IS NULL OR sls_price <= 0
                 THEN sls_sales / NULLIF(sls_quantity, 0) -- NULLIF avoids divide-by-zero
                 ELSE sls_price
            END AS sls_price
        FROM bronze.crm_sales_details;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- ------------------------------------------------------------
        -- Loading ERP Tables
        -- ------------------------------------------------------------
        PRINT '----------------------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '----------------------------------------------------------------';

        -- ------------------------------------------------------------
        -- Table:   silver.erp_cust_az12
        -- Purpose: Clean and load ERP customer birthdate and gender into the Silver layer.
        -- ------------------------------------------------------------
        -- Removes the 'NAS' prefix from customer IDs, sets future birthdates to NULL,
        -- and standardizes gender values ('Unknown' when missing). Hidden CR/LF
        -- characters from the source file are stripped so values match correctly.
        -- ------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT '>> Inserting Data Into: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                 ELSE cid
            END AS cid,
            CASE WHEN bdate > GETDATE() THEN NULL
                 ELSE bdate
            END AS bdate,
            CASE WHEN UPPER(TRIM(REPLACE(REPLACE(gen, CHAR(13), ''), CHAR(10), ''))) IN ('F', 'FEMALE') THEN 'Female'
                 WHEN UPPER(TRIM(REPLACE(REPLACE(gen, CHAR(13), ''), CHAR(10), ''))) IN ('M', 'MALE')   THEN 'Male'
                 ELSE 'Unknown'
            END AS gen
        FROM bronze.erp_cust_az12;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- ------------------------------------------------------------
        -- Table:   silver.erp_loc_a101
        -- Purpose: Clean and load ERP customer country data into the Silver layer.
        -- ------------------------------------------------------------
        -- Removes hyphens from customer IDs to match the CRM keys, and standardizes
        -- country names (DE -> Germany, US/USA -> United States, blank -> 'n/a').
        -- Hidden CR/LF characters are stripped before matching.
        -- ------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT '>> Inserting Data Into: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT
            REPLACE(cid, '-', '') AS cid,
            CASE WHEN TRIM(CHAR(13) + CHAR(10) + ' ' FROM cntry) = 'DE' THEN 'Germany'
                 WHEN TRIM(CHAR(13) + CHAR(10) + ' ' FROM cntry) IN ('US', 'USA') THEN 'United States'
                 WHEN TRIM(CHAR(13) + CHAR(10) + ' ' FROM cntry) = '' OR cntry IS NULL THEN 'n/a'
                 ELSE TRIM(CHAR(13) + CHAR(10) + ' ' FROM cntry)
            END AS cntry
        FROM bronze.erp_loc_a101;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- ------------------------------------------------------------
        -- Table:   silver.erp_px_cat_g1v2
        -- Purpose: Load ERP product categories into the Silver layer.
        -- ------------------------------------------------------------
        -- Loaded as-is. No cleaning or transformation was needed.
        -- ------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
        SELECT
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- ------------------------------------------------------------
        -- Total Load Time
        -- ------------------------------------------------------------
        SET @batch_end_time = GETDATE();
        PRINT '========================================================================';
        PRINT 'Silver Layer Loading Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '========================================================================';
    END TRY

    -- Runs only if a step above fails; the remaining loads are skipped
    BEGIN CATCH
        PRINT '========================================================================';
        PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();                    -- Description of the error
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);    -- SQL Server error code
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);      -- Helps pinpoint where the error was raised
        PRINT '========================================================================';
    END CATCH
END
GO

EXEC silver.load_silver
