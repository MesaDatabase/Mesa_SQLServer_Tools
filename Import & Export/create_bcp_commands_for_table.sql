/* generates BCP output commands for a single */
/* table in the database and writes tab delimited */
/* data to C:\temp */
/* output command looks like bcp dbo.FactProductInventory out c:\temp\dbo_FactProductInventory.dat -b 10000 -d AdventureWorksDW2012 -T -c -S CGROSSBOISE\SQL2012 */
/* paste the bcp command to a command prompt and run it */

USE [AdventureWorksDW2012];

DECLARE @servername sysname, @dbname sysname, @tablename sysname, @outputdir sysname

SELECT  @servername = @@SERVERNAME
       ,@dbname = DB_NAME()
       ,@outputdir = 'c:\temp\'
       ,@tablename = 'FactProductInventory'

SELECT 'bcp ' + OBJECT_SCHEMA_NAME(object_id) + '.' + name + ' out '
       + @outputdir + OBJECT_SCHEMA_NAME(object_id) + '_' + name + '.dat -b 10000 -d '
       + @dbname + ' -T -c -S ' + @servername
FROM sys.objects
WHERE type_desc = 'USER_TABLE'
  AND name = @tablename

