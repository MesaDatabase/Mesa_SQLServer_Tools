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

	SET @statement = N'DBCC SHOW_STATISTICS (['+ @sch + N'.' + @table + N'],' + @index + N')' + N'WITH STAT_HEADER'
    INSERT INTO #dbccstat EXEC sp_executesql @statement

	SET @i = @i + 1  
END

/* Present result                                                              */

SELECT * FROM #dbccstat order by 3 desc

/* Clean up                                                                    */

DROP TABLE #indexes
DROP TABLE #dbccstat