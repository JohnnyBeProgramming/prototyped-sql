USE master;
GO
----------------------------------------------------------------------------------
-- Create (blank) new database
----------------------------------------------------------------------------------
DECLARE @Target varchar(max) = 'Northwind'
----------------------------------------------------------------------------------
IF DB_ID(@Target) IS NOT NULL EXEC('DROP DATABASE ' + @Target + ';');
EXEC('CREATE DATABASE ' + @Target + ';');
GO
----------------------------------------------------------------------------------