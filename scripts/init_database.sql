/*
===========================
Ceate database and schemas
===========================
Scripts purpose:
	this script create database name 'DataWareHouse' after checking if it already exist.
	If database exist, it will dropped and recreated. Additionally the script sets up three schemas
	within the database: 'bronze', 'silver' and gold

WARNING:
	Running this script will drop the 'DataWareHouse' database if it exists.
	All data in database will be permanently deleted. make sure you have backups before running this script
*/

USE master;
GO

-- Drop and recreate 'DataWareHouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWareHouse')
BEGIN
	ALTER DATABASE DataWareHouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE DataWareHouse;
END
GO

-- Create the 'DataWareHouse' database 
CREATE  DATABASE DataWareHouse
GO

USE DataWareHouse
GO

-- Create Schemas
CREATE SCHEMA bronze
GO

CREATE SCHEMA silver
GO

CREATE SCHEMA gold 
GO