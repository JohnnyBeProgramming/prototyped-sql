select 
	s.name + '.' + t.name as [Table Name], 
	c.name as [Index Column], 
	i.name as [Index Name], 
	i.type_desc as [Index Type], 
	i.is_unique as [Is Unique]
FROM 
	sys.tables t inner join 
	sys.schemas s on t.schema_id = s.schema_id inner join 
	sys.indexes i on i.object_id = t.object_id inner join 
	sys.index_columns ic on ic.object_id = t.object_id inner join 
	sys.columns c on c.object_id = t.object_id and ic.column_id = c.column_id
WHERE 
	i.index_id > 0    
and i.type in (1, 2) -- clustered & nonclustered only
and i.is_primary_key = 0 -- do not include PK indexes
and i.is_unique_constraint = 0 -- do not include UQ
and i.is_disabled = 0
and i.is_hypothetical = 0
and ic.key_ordinal > 0
--and t.name IN ('YOUR_TABLE_NAME', 'ANOTHER_TABLE_NAME')
ORDER BY [Table Name] ASC, i.name ASC, ic.key_ordinal



