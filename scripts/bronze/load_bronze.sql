/*
===============================================================================
Script: Load Bronze Layer (Source -> Bronze)
===============================================================================
Purpose:
    Loads raw data from CSV files into the Bronze layer of the data warehouse
    and prints how long each table load and the whole run take.

Bronze Layer:
    The first layer of the Medallion Architecture (Bronze, Silver, Gold).
    It stores source data as it arrives, with no cleaning or transformation.

Load Type:
    Full load. Each table is emptied and reloaded on every run, so the
    Bronze layer always mirrors the current source files and reruns never
    create duplicates. The load is wrapped in a stored procedure, so the
    whole Bronze layer can be refreshed with a single command:
        EXEC bronze.load_bronze;

WARNING:
    Running this procedure deletes all existing rows in the six bronze tables
    before reloading them.

Important: Replace <datasets_path> in the file paths below with the location of
the datasets folder as seen by SQL Server (e.g. /var/opt/mssql/datasets when
SQL Server runs in Docker).
===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    -- Timers for each table load and for the whole run
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        PRINT '========================================================================';
        PRINT 'Loading the Bronze Layer';
        PRINT '========================================================================';

        -- ------------------------------------------------------------
        -- Loading CRM Tables
        -- ------------------------------------------------------------
        PRINT '----------------------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '----------------------------------------------------------------';

        -- Each table follows the same steps: truncate, bulk insert, print duration
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT '>> Inserting Data Into: bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info
        FROM '<datasets_path>/source_crm/cust_info.csv'
        WITH (
            FIRSTROW = 2,             -- Skip the header row
            FIELDTERMINATOR = ',',    -- Comma-separated columns
            TABLOCK                   -- Lock the table for a faster load
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT '>> Inserting Data Into: bronze.crm_prd_info';
        BULK INSERT bronze.crm_prd_info
        FROM '<datasets_path>/source_crm/prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '>> Inserting Data Into: bronze.crm_sales_details';
        BULK INSERT bronze.crm_sales_details
        FROM '<datasets_path>/source_crm/sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- ------------------------------------------------------------
        -- Loading ERP Tables
        -- ------------------------------------------------------------
        PRINT '----------------------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '----------------------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT '>> Inserting Data Into: bronze.erp_cust_az12';
        BULK INSERT bronze.erp_cust_az12
        FROM '<datasets_path>/source_erp/CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
        BULK INSERT bronze.erp_loc_a101
        FROM '<datasets_path>/source_erp/LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM '<datasets_path>/source_erp/PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- ------------------------------------------------------------
        -- Total Load Time
        -- ------------------------------------------------------------
        SET @batch_end_time = GETDATE();
        PRINT '========================================================================';
        PRINT 'Bronze Layer Loading Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '========================================================================';
    END TRY

    -- Runs only if a step above fails; the remaining loads are skipped
    BEGIN CATCH
        PRINT '========================================================================';
        PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();                    -- Description of the error
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);    -- SQL Server error code
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);      -- Helps pinpoint where the error was raised
        PRINT '========================================================================';
    END CATCH
END
GO
