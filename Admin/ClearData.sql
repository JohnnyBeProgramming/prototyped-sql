/*
------------------------------------------------------
-- NB: MAKE SURE SURE YOU HAVE SELECTED THE CORRECT DB
------------------------------------------------------

EXEC sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'

DECLARE @name VARCHAR(max) -- Table name  
DECLARE db_cursor CURSOR FOR  
SELECT s.name + '.' + t.name AS TableName 
FROM sys.tables t LEFT JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0 ORDER BY s.name ASC  

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @name  
WHILE @@FETCH_STATUS = 0  
BEGIN  
       EXEC ('DELETE FROM ' + @name)
       FETCH NEXT FROM db_cursor INTO @name  
END  
CLOSE db_cursor  
DEALLOCATE db_cursor

*/