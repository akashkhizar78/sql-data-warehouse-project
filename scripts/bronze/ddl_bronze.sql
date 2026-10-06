/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates the tables in the 'bronze' schema for the CRM and ERP source data. 
    It performs the following actions:
    - Drops each bronze table if it already exists.
    - Creates the bronze tables with their column definitions.

Data Sources:
    Two source systems, each delivered as CSV files:
    - CRM: cust_info, prd_info, sales_details
    - ERP: LOC_A101, CUST_AZ12, PX_CAT_G1V2
===============================================================================
*/

-- ------------------------------------------------------------
-- Creating CRM Tables
-- ------------------------------------------------------------

-- CRM Customer Information
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;

CREATE TABLE bronze.crm_cust_info (
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cat_gndr NVARCHAR(50),
    cst_create_date DATE
);

-- CRM Product Information
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;

CREATE TABLE bronze.crm_prd_info (
    prd_id INT,
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(50),
    prd_cost INT,
    prd_line NVARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt DATETIME
);

-- CRM Sales Details
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT,
    sls_ord_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT
);

-- ------------------------------------------------------------
-- Creating ERP Tables
-- ------------------------------------------------------------

-- ERP Location Information
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;

CREATE TABLE bronze.erp_loc_a101 (
	cid NVARCHAR(50),
    cntry NVARCHAR(50)
);

-- ERP Customer Information
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;

CREATE TABLE bronze.erp_cust_az12 (
	cid NVARCHAR(50),
    bdate DATE,
    gen NVARCHAR (50)
);

-- ERP Product Category Information 
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;

CREATE TABLE bronze.erp_px_cat_g1v2 (
	id NVARCHAR(50),
    cat NVARCHAR(50),
    subcat NVARCHAR(50),
    maintenance NVARCHAR(50)
);

