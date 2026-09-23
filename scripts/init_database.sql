/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouse' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas: 
    'bronze', 'silver', and 'gold'. In MySQL, a schema is the same as a database, so these are created 
    as separate databases alongside 'DataWarehouse', not inside it.
	
WARNING:
    Running this script will drop the 'DataWarehouse', 'bronze', 'silver', and 'gold' databases if they exist. 
    All data in them will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

-- Drop and recreate the 'DataWarehouse' database
DROP DATABASE IF EXISTS DataWarehouse;

-- Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
USE DataWarehouse;

-- Drop and recreate Schemas
DROP SCHEMA IF EXISTS bronze;
CREATE SCHEMA bronze;

DROP SCHEMA IF EXISTS silver;
CREATE SCHEMA silver;

DROP SCHEMA IF EXISTS gold;
CREATE SCHEMA gold;
