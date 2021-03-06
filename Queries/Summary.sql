DECLARE @TableToCheck TABLE ( [Name] VARCHAR(max) )
/*
INSERT INTO @TableToCheck ([Name]) VALUES 
('[INCLUDE_TABLE_NAME]'),
('[INCLUDE_TABLE_NAME]'),
('[INCLUDE_TABLE_NAME]')
*/
INSERT INTO @TableToCheck 
SELECT s.Name + '.' + t.NAME AS [Name] 
FROM sys.tables t INNER JOIN sys.schemas s ON s.schema_id = t.schema_id AND t.type = 'U'


SELECT 
	 [Name] AS [Table Name]
	,CASE 
		WHEN OBJECT_ID([Name]) IS NULL 
		THEN ' '
		ELSE 'Yes'
	 END AS [Exists]
	 /*
    ,(
		SELECT [COLUMN_NAME], *
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE OBJECT_ID('dbo.aspnet_Roles') = OBJECT_ID([TABLE_SCHEMA] + '.' + [TABLE_NAME])
		  AND COLUMNPROPERTY(OBJECT_ID('dbo.aspnet_Roles'), [COLUMN_NAME], 'IsIdentity') = 1
		ORDER BY TABLE_NAME
	) AS [Identity Column]
	*/
FROM @TableToCheck 
ORDER BY [Name] ASC