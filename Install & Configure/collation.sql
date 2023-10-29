--What Collation is SQL installed under?
SELECT SERVERPROPERTY('COLLATION')

--Which collations are available to me?
SELECT Name, Description FROM fn_helpcollations()

--Which databases have a different collation to the server default?
SELECT 
 NAME AS DATABASE_NAME,
 DATABASEPROPERTYEX(NAME,'COLLATION') AS DBCOLLATION,
 SERVERPROPERTY('COLLATION') AS SERVERCOLLATION,
FROM SYS.DATABASES
WHERE CONVERT(SYSNAME,DATABASEPROPERTYEX(NAME,'COLLATION')) <> SERVERPROPERTY('COLLATION')

--Show me the collation for each column in my database
SELECT 
  C.TABLE_CATALOG AS DATABASE_NAME,
  C.TABLE_SCHEMA,
  C.TABLE_NAME,
  C.COLUMN_NAME,
  DATA_TYPE,
  SERVERPROPERTY('COLLATION') AS SERVER_COLLATION,
  CONVERT(SYSNAME,DATABASEPROPERTYEX(D.NAME,'COLLATION')) AS DATABASE_COLLATION,
  C.COLLATION_NAME AS COLUMN_COLLATION,
FROM INFORMATION_SCHEMA.COLUMNS C
  INNER JOIN SYS.DATABASES D ON DB_ID(C.TABLE_CATALOG) = DB_ID(D.NAME)
WHERE DATA_TYPE IN ('VARCHAR' ,'CHAR','NVARCHAR','NCHAR','TEXT','NTEXT')

--Show me differences in collation settings on my server
IF EXISTS (SELECT * FROM TEMPDB.DBO.SYSOBJECTS WHERE ID = OBJECT_ID('tempdb.dbo.#CollationComparison')) DROP TABLE #CollationComparison

CREATE TABLE #CollationComparison
  (Database_Name SYSNAME 
   Table_Schema SYSNAME
   Table_Name SYSNAME
   Column_Name SYSNAME
   Server_Collation SYSNAME
   Database_Collation SYSNAME
   Column_Collation SYSNAME)

DECLARE @SQL NVARCHAR(MAX)
DECLARE @dbname NVARCHAR(200)
DECLARE dbcursor CURSOR FOR

select name from sys.databases

OPEN dbcursor
FETCH NEXT FROM dbcursor INTO @dbname
WHILE @@FETCH_STATUS = 0
BEGIN
 print @dbname
 SET @SQL = '
	INSERT INTO #CollationComparison
		(Database_Name,
		Table_Schema,
		Table_Name,
		Column_Name,
		Server_Collation,
		Database_Collation,
		Column_Collation)
	 SELECT 
		C.TABLE_CATALOG AS DATABASE_NAME,
		C.TABLE_SCHEMA,
		C.TABLE_NAME,
		C.COLUMN_NAME,
		CONVERT(VARCHAR,SERVERPROPERTY(''COLLATION'')) AS SERVER_COLLATION,
		CONVERT(SYSNAME,DATABASEPROPERTYEX(D.NAME,''COLLATION'')) AS DATABASE_COLLATION,
		C.COLLATION_NAME AS COLUMN_COLLATION
		FROM [' + @dbname + '].INFORMATION_SCHEMA.COLUMNS C
		  INNER JOIN SYS.DATABASES D ON DB_ID(C.TABLE_CATALOG) = DB_ID(D.NAME)
		WHERE DATA_TYPE IN (''VARCHAR'' ,''CHAR'',''NVARCHAR'',''NCHAR'',''TEXT'',''NTEXT'')'

exec sp_executesql @SQL
print @sql

FETCH NEXT FROM dbcursor INTO @dbname
END

CLOSE dbcursor
DEALLOCATE dbcursor

SELECT DISTINCT Server_Collation,Database_Collation,Database_Name FROM #CollationComparison WHERE Server_Collation <> Database_Collation
SELECT DISTINCT * FROM #CollationComparison WHERE Column_Collation <> Database_Collation

--show all characters in a collation
--=============================================================================
--      Setup
--=============================================================================    
USE TempDB     --DB that everyone has where we can cause no harm    
SET NOCOUNT ON --Supress the auto-display of rowcounts for appearance/speed
DECLARE @StartTime DATETIME    --Timer to measure total duration    
SET @StartTime = GETDATE() --Start the timer

--=============================================================================
--      Create and populate a Tally table
--=============================================================================
--===== Conditionally drop      
IF OBJECT_ID('dbo.Tally') IS NOT NULL         
DROP TABLE dbo.Tally

--===== Create and populate the Tally table on the fly 
SELECT TOP 11000 --equates to more than 30 years of dates        
	IDENTITY(INT,1,1) AS N   
INTO dbo.Tally  
FROM Master.dbo.SysColumns sc1,        
	Master.dbo.SysColumns sc2

--===== Add a Primary Key to maximize performance  
ALTER TABLE dbo.Tally    
ADD CONSTRAINT PK_Tally_N         
PRIMARY KEY CLUSTERED (N) 
WITH FILLFACTOR = 100

--===== Let the public use it  
GRANT SELECT, REFERENCES ON dbo.Tally TO PUBLIC

--===== Display the total duration 
SELECT STR(DATEDIFF(ms,@StartTime,GETDATE())) + ' Milliseconds duration'

select CHAR(N), N from Tally 
where char(N) between '0' and 'Z' collate SQL_Latin1_General_CP1_CI_AS 
  and N < 256 
order by CHAR(N) 







--So, you've got collation differences. Now what?
-- at query level in a WHERE clause ...
SELECT columnlist 
FROM table 
WHERE searchedcolumn COLLATE SQL_Latin1_General_CP1_CS_AS = 'Searched Text'

--in a join
SELECT columnlist 
FROM table1
  LEFT OUTER JOIN table2 ON table1.textid = table2.textid COLLATE SQL_Latin1_General_CP1_CI_AI
--Using Collate in this way will prevent the query optimiser from using optimal indexes and creating an efficient execution plan.

--Change Collation of a column
ALTER TABLE tablename
ALTER COLUMN columnname datatype 
COLLATE collationname

--Change Collation of a database
ALTER DATABASE [adventureworks] COLLATE Latin1_General_CS_AS
--Then change each column individually using the ALTER TABLE ... ALTER COLUMN... syntax.



