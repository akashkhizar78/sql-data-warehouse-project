/*
===============================================================================
Script: Load Bronze Layer (Source -> Bronze)
===============================================================================
Purpose:
    Loads raw data from CSV files into the Bronze layer of the data warehouse
    and records how long each table load and the whole run take.

Bronze Layer:
    The first layer of the Medallion Architecture (Bronze, Silver, Gold).
    It stores source data as it arrives, with no cleaning or transformation.

Load Type:
    Full load. Each table is emptied and reloaded on every run, so the
    Bronze layer always mirrors the current source files and reruns never
    create duplicates. It is a plain script and not a stored procedure,
    because MySQL does not allow LOAD DATA inside a stored procedure.

WARNING:
    Running this script deletes all existing rows in the six bronze tables
    before reloading them.
    
Important: Local file loading must be enabled on both the MySQL server and the MySQL Workbench connection.
===============================================================================
*/


-- Record the start of the whole script (NOW(6) keeps microsecond precision).
SET @script_start = NOW(6);


-- ------------------------------------------------------------
-- Loading CRM Tables
-- ------------------------------------------------------------

-- Record the start of this table load. The variable is reused by every table below.
SET @table_start = NOW(6);

-- Delete existing rows so a rerun replaces the data and does not duplicate it.
-- TRUNCATE is faster than DELETE and cannot be rolled back.
TRUNCATE TABLE bronze.crm_cust_info;

-- Load the CSV file into the table. LOCAL means the file is read from this
-- computer and sent to the server, and the path must be the full file path.
LOAD DATA LOCAL INFILE '/Users/akashkhizar/Desktop/Portfolio/SQL Data Warehouse Project/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
INTO TABLE bronze.crm_cust_info
FIELDS TERMINATED BY ','        -- Columns are separated by commas
ENCLOSED BY '"'                 -- Values wrapped in double quotes are loaded without the quotes
LINES TERMINATED BY '\r\n'      -- Each row ends with a Windows line break
IGNORE 1 ROWS;                  -- Skip the header row

-- Record the end time and show the load duration in seconds.
SET @table_end = NOW(6);

SELECT
    'bronze.crm_cust_info' AS table_name,   -- Table that was loaded
    @table_start AS start_time,             -- Time recorded before the truncate
    @table_end AS end_time,                 -- Time recorded after the load finished
    -- Difference in microseconds, divided by 1,000,000 to get seconds, rounded to 3 decimals
    ROUND(TIMESTAMPDIFF(MICROSECOND, @table_start, @table_end) / 1000000, 3) AS duration_seconds;


SET @table_start = NOW(6);

TRUNCATE TABLE bronze.crm_prd_info;

LOAD DATA LOCAL INFILE '/Users/akashkhizar/Desktop/Portfolio/SQL Data Warehouse Project/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
INTO TABLE bronze.crm_prd_info
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SET @table_end = NOW(6);

SELECT
    'bronze.crm_prd_info' AS table_name,
    @table_start AS start_time,
    @table_end AS end_time,
    ROUND(TIMESTAMPDIFF(MICROSECOND, @table_start, @table_end) / 1000000, 3) AS duration_seconds;


SET @table_start = NOW(6);

TRUNCATE TABLE bronze.crm_sales_details;

LOAD DATA LOCAL INFILE '/Users/akashkhizar/Desktop/Portfolio/SQL Data Warehouse Project/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
INTO TABLE bronze.crm_sales_details
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SET @table_end = NOW(6);

SELECT
    'bronze.crm_sales_details' AS table_name,
    @table_start AS start_time,
    @table_end AS end_time,
    ROUND(TIMESTAMPDIFF(MICROSECOND, @table_start, @table_end) / 1000000, 3) AS duration_seconds;


-- ------------------------------------------------------------
-- Loading ERP Tables
-- ------------------------------------------------------------

SET @table_start = NOW(6);

TRUNCATE TABLE bronze.erp_loc_a101;

LOAD DATA LOCAL INFILE '/Users/akashkhizar/Desktop/Portfolio/SQL Data Warehouse Project/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv'
INTO TABLE bronze.erp_loc_a101
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SET @table_end = NOW(6);

SELECT
    'bronze.erp_loc_a101' AS table_name,
    @table_start AS start_time,
    @table_end AS end_time,
    ROUND(TIMESTAMPDIFF(MICROSECOND, @table_start, @table_end) / 1000000, 3) AS duration_seconds;


SET @table_start = NOW(6);

TRUNCATE TABLE bronze.erp_cust_az12;

LOAD DATA LOCAL INFILE '/Users/akashkhizar/Desktop/Portfolio/SQL Data Warehouse Project/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv'
INTO TABLE bronze.erp_cust_az12
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SET @table_end = NOW(6);

SELECT
    'bronze.erp_cust_az12' AS table_name,
    @table_start AS start_time,
    @table_end AS end_time,
    ROUND(TIMESTAMPDIFF(MICROSECOND, @table_start, @table_end) / 1000000, 3) AS duration_seconds;


SET @table_start = NOW(6);

TRUNCATE TABLE bronze.erp_px_cat_g1v2;

LOAD DATA LOCAL INFILE '/Users/akashkhizar/Desktop/Portfolio/SQL Data Warehouse Project/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv'
INTO TABLE bronze.erp_px_cat_g1v2
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SET @table_end = NOW(6);

SELECT
    'bronze.erp_px_cat_g1v2' AS table_name,
    @table_start AS start_time,
    @table_end AS end_time,
    ROUND(TIMESTAMPDIFF(MICROSECOND, @table_start, @table_end) / 1000000, 3) AS duration_seconds;


-- ------------------------------------------------------------
-- Total Load Time
-- ------------------------------------------------------------

-- Record the end of the whole script and show the total duration in seconds.
SET @script_end = NOW(6);

SELECT
    @script_start AS script_start_time,     -- Time recorded at the top of the script
    @script_end AS script_end_time,         -- Time recorded after the last table loaded
    -- Same calculation as above, this time covering all six tables together
    ROUND(TIMESTAMPDIFF(MICROSECOND, @script_start, @script_end) / 1000000, 3) AS total_duration_seconds;
