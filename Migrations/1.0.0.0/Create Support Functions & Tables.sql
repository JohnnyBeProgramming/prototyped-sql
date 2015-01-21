/* ---------------------------------------------------------------
Create The Schema (proto)
--------------------------------------------------------------- * /
*/
DECLARE @SchemaName varchar(16) SET @SchemaName = 'proto'
IF NOT EXISTS(SELECT schema_name FROM information_schema.schemata WHERE schema_name = @SchemaName)
BEGIN EXEC('CREATE SCHEMA [' + @SchemaName + '] AUTHORIZATION [dbo]') END
GO

/* ---------------------------------------------------------------
Create Table - [@SchemaName].[ArchiveInfo]
--------------------------------------------------------------- */
IF NOT EXISTS(SELECT name FROM sys.tables WHERE object_id = OBJECT_ID('[dbo].[ArchiveInfo]'))
BEGIN
CREATE TABLE [dbo].[ArchiveInfo](
	[ArchiveID] [int] IDENTITY(1,1) NOT NULL,
	[ArchiveGroup] [varchar](255) NOT NULL,
	[ArchiveAction] [varchar](255) NOT NULL,
	[ArchiveTable] [varchar](255) NOT NULL,
	[ArchiveKey] [varchar](255) NOT NULL,
	[ArchiveCondition] [varchar](255) NOT NULL,
 CONSTRAINT [PK_ArchiveInfo] PRIMARY KEY CLUSTERED 
(
	[ArchiveID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/* ---------------------------------------------------------------
Create Procedure - [dbo].[sp_ArchivePreview]
--------------------------------------------------------------- */
IF Object_ID('[dbo].[sp_ArchivePreview]') IS NOT NULL 
DROP PROCEDURE [dbo].[sp_ArchivePreview]
GO
CREATE PROCEDURE [dbo].[sp_ArchivePreview]
	@ArchiveGroup varchar(max) = '%'
WITH EXECUTE AS CALLER
AS
BEGIN
	DECLARE @Action varchar(max)
	DECLARE @Table varchar(max)
	DECLARE @KeyField varchar(max)
	DECLARE @Condition varchar(max)
	DECLARE @CountResult TABLE ( [RowCount] int NOT NULL )
	DECLARE @ArchiveInfo TABLE
	(
	   [Table] varchar(max) NOT NULL
	  ,[ArchiveType] varchar(max) NULL
	  ,[TotalRows] int NOT NULL
	  ,[ToArchive] int NOT NULL  
	)

	DECLARE @archive_id int
	DECLARE db_cursor CURSOR FOR  
	SELECT [ArchiveID]
	FROM   [dbo].[ArchiveInfo]
	WHERE ([ArchiveGroup] LIKE @ArchiveGroup)
	ORDER BY [ArchiveTable] ASC

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @archive_id 
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		---------------------------------------------------------------------- 
		-- Define the total and archive counters
		----------------------------------------------------------------------
		DECLARE @TotalRows int = 0
		DECLARE @ArchiveRows int = 0
		
		-- Get the current Archive Item
		SELECT TOP 1
			   @Action = [ArchiveAction]
			  ,@Table = [ArchiveTable]
			  ,@KeyField = [ArchiveKey]
			  ,@Condition = [ArchiveCondition]
		  FROM [dbo].[ArchiveInfo]
		WHERE ([ArchiveID] = @archive_id)		
		
		-- Get the total count for the current item
		DELETE FROM @CountResult
		INSERT INTO @CountResult EXEC ('SELECT COUNT(*) FROM ' + @Table + ' WITH (NOLOCK)')
		SELECT @TotalRows = [RowCount] FROM @CountResult

		-- Check the type of operation and determine value(s)
		IF (@Action = 'Static')
		BEGIN
			-- Contents static, no archiving
			SELECT @ArchiveRows = 0
		END
		ELSE IF (@Action = 'Expires')
		BEGIN
			-- Archive according to expiry time
			----------------------------------------------------------------------
			DELETE FROM @CountResult
			INSERT INTO @CountResult EXEC ('SELECT COUNT(*) FROM ' + @Table + ' WHERE NOT(' + @Condition + ')')
			SELECT @ArchiveRows = [RowCount] FROM @CountResult
			----------------------------------------------------------------------
		END
		ELSE IF (@Action = 'Inactive')
		BEGIN
			-- Archive inactive rows
			-- SELECT @ArchiveRows = COUNT(*) FROM [dbo].[AARTDRV] WHERE NOT([DRV_ACTIVE] = 'T') 
			----------------------------------------------------------------------
			DELETE FROM @CountResult
			INSERT INTO @CountResult EXEC ('SELECT COUNT(*) FROM ' + @Table + ' WHERE NOT(' + @Condition + ')')
			SELECT @ArchiveRows = [RowCount] FROM @CountResult
			----------------------------------------------------------------------
		END
		ELSE IF (@Action = 'Exclusive')
		BEGIN
			-- Archive any multiples of a given record
			SELECT @ArchiveRows = 0
		END
		ELSE IF (@Action = 'Linked')
		BEGIN
			-- Archive all linked data for the specified rows
			SELECT @ArchiveRows = 0
		END
		ELSE 
		BEGIN
			-- Default: No archiving defined
			SELECT @ArchiveRows = 0
		END

		-- Add current result to the list
		INSERT INTO @ArchiveInfo
		SELECT 
			 @Table AS [Table]
			,@Action AS [ArchiveType]
			,@TotalRows AS [TotalRows]
			,@ArchiveRows AS [ToArchive]
					
		----------------------------------------------------------------------
	FETCH NEXT FROM db_cursor INTO @archive_id
	END  
	CLOSE db_cursor  
	DEALLOCATE db_cursor

	SELECT 
		 [Table]
		,[ArchiveType]
		,[TotalRows]
		,[ToArchive]
		,CASE [TotalRows]
			WHEN 0 THEN 0
			ELSE (100 * [ToArchive] / [TotalRows]) 
		 END AS [Reduction (%)]
	FROM @ArchiveInfo		   
END
GO


/* ---------------------------------------------------------------
Create Procedure - [dbo].[sp_Archive]
--------------------------------------------------------------- */
IF Object_ID('[dbo].[sp_ArchiveExecute]') IS NOT NULL 
DROP PROCEDURE [dbo].[sp_ArchiveExecute]
GO
CREATE PROCEDURE [dbo].[sp_ArchiveExecute]
	@ArchiveDB varchar(max),
	@ArchiveGroup varchar(max) = '%',
	@TargetTable varchar(max) = NULL
WITH EXECUTE AS CALLER
AS
BEGIN
	DECLARE @Action varchar(max)
	DECLARE @Table varchar(max)
	DECLARE @KeyField varchar(max)
	DECLARE @Condition varchar(max)
	DECLARE @CountResult TABLE ( [RowCount] int NOT NULL )
	DECLARE @ArchiveInfo TABLE
	(
	   [Table] varchar(max) NOT NULL
	  ,[ArchiveType] varchar(max) NULL
	  ,[TotalRows] int NOT NULL
	  ,[ToArchive] int NOT NULL  
	)

	DECLARE @archive_id int
	DECLARE db_cursor CURSOR FOR  
	SELECT [ArchiveID]
	FROM   [dbo].[ArchiveInfo]
	WHERE ([ArchiveGroup] LIKE @ArchiveGroup)
	ORDER BY [ArchiveTable] ASC

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @archive_id 
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		---------------------------------------------------------------------- 
		-- Define the total and archive counters
		----------------------------------------------------------------------
		DECLARE @TotalRows int = 0
		DECLARE @ArchiveRows int = 0
		
		-- Get the current Archive Item
		SELECT TOP 1
			   @Action = [ArchiveAction]
			  ,@Table = [ArchiveTable]
			  ,@KeyField = [ArchiveKey]
			  ,@Condition = [ArchiveCondition]
		  FROM [dbo].[ArchiveInfo]
		WHERE ([ArchiveID] = @archive_id)		
		
		IF (@TargetTable IS NULL OR @TargetTable = @Table)
		BEGIN
			-- Get the total count for the current item
			DELETE FROM @CountResult
			INSERT INTO @CountResult EXEC ('SELECT COUNT(*) FROM ' + @Table)
			SELECT @TotalRows = [RowCount] FROM @CountResult

			-- Check the type of operation and determine value(s)
			IF (@Action = 'Static')
			BEGIN
				-- Contents static, no archiving
				SELECT @ArchiveRows = 0
			END
			ELSE IF (@Action = 'Expires')
			BEGIN
				----------------------------------------------------------------------
				-- Archive according to expiry time
				----------------------------------------------------------------------
				EXEC 
				(
					'INSERT INTO ' + @ArchiveDB + '.' + @Table + ' '
				  + 'SELECT * FROM ' + @Table + ' WHERE NOT(' + @Condition + ')'
				)			
				EXEC
				(
					'DELETE FROM ' + @Table + ' WHERE ' + @KeyField + ' IN ( '
				  + 'SELECT ' + @KeyField + ' FROM ' + @ArchiveDB + '.' + @Table + ''
				  + ')'
				)			
				----------------------------------------------------------------------
			END
			ELSE IF (@Action = 'Inactive')
			BEGIN
				----------------------------------------------------------------------
				-- Archive inactive rows
				----------------------------------------------------------------------
				EXEC 
				(
					'INSERT INTO ' + @ArchiveDB + '.' + @Table + ' '
				  + 'SELECT * FROM ' + @Table + ' WHERE NOT(' + @Condition + ')'
				)			
				EXEC
				(
					'DELETE FROM ' + @Table + ' WHERE ' + @KeyField + ' IN ( '
				  + 'SELECT ' + @KeyField + ' FROM ' + @ArchiveDB + '.' + @Table + ''
				  + ')'
				)			
				----------------------------------------------------------------------
			END
			ELSE IF (@Action = 'Exclusive')
			BEGIN
				-- Archive any multiples of a given record
				SELECT @ArchiveRows = 0
			END
			ELSE IF (@Action = 'Linked')
			BEGIN
				-- Archive all linked data for the specified rows
				SELECT @ArchiveRows = 0
			END
			ELSE 
			BEGIN
				-- Default: No archiving defined
				SELECT @ArchiveRows = 0
			END

			-- Get the updated count for the current item
			DELETE FROM @CountResult
			INSERT INTO @CountResult EXEC ('SELECT COUNT(*) FROM ' + @Table)
			SELECT @ArchiveRows = (@TotalRows - [RowCount]) FROM @CountResult

			-- Add current result to the list
			INSERT INTO @ArchiveInfo
			SELECT 
				 @Table AS [Table]
				,@Action AS [ArchiveType]
				,@TotalRows AS [TotalRows]
				,@ArchiveRows AS [ToArchive]
		END
		----------------------------------------------------------------------
	FETCH NEXT FROM db_cursor INTO @archive_id
	END  
	CLOSE db_cursor  
	DEALLOCATE db_cursor

	SELECT 
		 [Table]
		,[ArchiveType]
		,[TotalRows]
		,[ToArchive]
		,CASE [TotalRows]
			WHEN 0 THEN 0
			ELSE (100 * [ToArchive] / [TotalRows]) 
		 END AS [Reduction (%)]
	FROM @ArchiveInfo	
END
GO