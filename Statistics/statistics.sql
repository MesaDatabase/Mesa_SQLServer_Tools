/* This script returns output from DBCC SHOW_STATISTICS ... WITH STAT_HEADER */
/* for all schemas, tables and indexes in the current database               */
/* 2009-02-17, elisabeth@sqlserverland.com, PROVIDED "AS IS"                 */

DECLARE @i int  
DECLARE @sch sysname
DECLARE @table sysname
DECLARE @index sysname
DECLARE @Statement nvarchar(300)
SET @i = 1  

/* Table to hold the output from DBCC SHOW_STATISTICS                         */
CREATE TABLE #dbccStat
(
	IdxName sysname
	, Updated datetime
	, Rows int
	, RowsSampled int
	, Steps int
	, Density int
	, AvgKeyLength int
	, StringIdx char (3)
	, FilterExp varchar(500)
	, UnfilteredRows int
)

/* Table to hold information about all indexes for all tables and schemas     */

CREATE TABLE #indexes  
(
	myid int identity
	, mySch sysname
	, myTbl sysname
	, myIdx sysname
)

/* Insert data about all user tables (type = 'u') and their indexes,           */
/* in #indexes. Heaps (si.index_id  > 0) and system tables (si.object_id >100) */
/* are excluded.                                                               */

INSERT INTO #indexes (mySch, myTbl, myIdx)  
	SELECT schema_name(so.schema_id),object_name(si.object_id), si.name 
	FROM sys.indexes si INNER JOIN sys.objects so ON si.object_id = so.object_id
	WHERE si.object_id >100
	AND so.type = 'U'
	AND si.index_id  > 0

/* Loop through all rows in #indexes                                           */

WHILE  
@i < (SELECT max(myid) FROM #indexes) 

BEGIN
	SELECT @sch = mySch, @table=myTbl, @index = myIdx
	FROM #indexes  
	WHERE myid = @i  

	SET @statement = N'DBCC SHOW_STATISTICS (['+ @sch + N'.' + @table + N'],[' + @index + N'])' + N'WITH STAT_HEADER'
	--print(@statement)
    INSERT INTO #dbccstat EXEC sp_executesql @statement

	SET @i = @i + 1  
END

/* Present result                                                              */

SELECT 
  db_name() as DbName,
  schema_name(s2.schema_id) as SchName,
  object_name(s1.object_id) as TblName,
  t1.*,
  (RowsSampled*1.0/Rows*1.0)*100 as SamplePct
FROM #dbccstat as t1
  join sys.indexes as s1 on t1.IdxName = s1.name
  join sys.objects as s2 on s1.object_id = s2.object_id
order by 1,2,3

/* Clean up                                                                    */

DROP TABLE #indexes
DROP TABLE #dbccstat