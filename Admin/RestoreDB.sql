USE master;
GO
----------------------------------------------------------------------------------
-- Restore database from a backup file on disk
----------------------------------------------------------------------------------
DECLARE @Target varchar(max) = '$(TargetName)'
DECLARE @Source varchar(max) = '$(BackupFile)' -- .\Backups\Northwind.bak
DECLARE @Folder varchar(max) --'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA'
----------------------------------------------------------------------------------
print @Source
IF (DB_ID(@Target) IS NOT NULL) EXEC('DROP DATABASE ' + @Target + ';');
IF (@Folder IS NULL) SELECT @Folder = SUBSTRING(physical_name, 1, CHARINDEX(N'master.mdf', LOWER(physical_name)) - 1) FROM master.sys.master_files WHERE database_id = 1 AND file_id = 1
PRINT('Restoring to: ' + @Folder)
EXEC('
RESTORE DATABASE ' + @Target + '
	FROM DISK =  ''' + @Source + '''
	WITH REPLACE, 
	MOVE ''Northwind''		TO ''' + @Folder + '\' + @Target + '.mdf'', 
	MOVE ''Northwind_Log''	TO ''' + @Folder + '\' + @Target + '.ldf'';
');
GO
----------------------------------------------------------------------------------