/******************************************************************************
**    File: GetTableSpaceUsage.sql
**    Name: Get Table Space Useage for a specific schema
**    Auth: Robert C. Cain
**    Date: 01/27/2008
**
**    Desc: Calls the sp_spaceused proc for each table in a schema and returns
**        the Table Name, Number of Rows, and space used for each table.
**
**    Called by:
**     n/a  As needed
**
**    Input Parameters:
**     In the code check the value of @schemaname, if you need it for a
**     schema other than dbo be sure to change it.
**
**    Output Parameters:
**     NA
*******************************************************************************/

/**/
/* Drop the temp table if it's there from a previous run                     */
/**/
if object_id(N'tempdb..[#TableSizes]') is not null
  drop table #TableSizes ;
go

/**/
/* Create the temp table                                                     */
/**/
create table #TableSizes
  (
    [Table Name] nvarchar(128)   /* Name of the table */
  , [Number of Rows] char(11)    /* Number of rows existing in the table. */
  , [Reserved Space] varchar(18) /* Reserved space for table. */
  , [Data Space] varchar(18)    /* Amount of space used by data in table. */
  , [Index Size] varchar(18)    /* Amount of space used by indexes in table. */
  , [Unused Space] varchar(18)   /* Amount of space reserved but not used. */
  ) ;
go

/**/
/* Load the temp table                                                        */
/**/
declare @schemaname varchar(256) ;
-- Make sure to set next line to the Schema name you want!
set @schemaname = 'dbo' ;

-- Create a cursor to cycle through the names of each table in the schema
declare curSchemaTable cursor
  for select sys.schemas.name + '.' + sys.objects.name
      from    sys.objects
    		, sys.schemas
      where   object_id > 100
    		  and sys.schemas.name = @schemaname
    		  /* For a specific table uncomment next line and supply name */
    		  --and sys.objects.name = 'specific-table-name-here'    
    		  and type_desc = 'USER_TABLE'
    		  and sys.objects.schema_id = sys.schemas.schema_id ;

open curSchemaTable ;
declare @name varchar(256) ;  /* This holds the name of the current table*/

-- Now loop thru the cursor, calling the sp_spaceused for each table
fetch curSchemaTable into @name ;
while ( @@FETCH_STATUS = 0 )
  begin    
    insert into #TableSizes
    		exec sp_spaceused @objname = @name ;       
    fetch curSchemaTable into @name ;   
  end

/* Important to both close and deallocate! */
close curSchemaTable ;     
deallocate curSchemaTable ;


/**/
/* Feed the results back                                                     */
/**/
select [Table Name]
      , [Number of Rows]
      , [Reserved Space]
      , [Data Space]
      , [Index Size]
      , [Unused Space]
from    [#TableSizes]
order by [Table Name] ;

/**/
/* Remove the temp table                                                     */
/**/
drop table #TableSizes ;