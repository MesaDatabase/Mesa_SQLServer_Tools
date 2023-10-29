--update user mode on all databases
USE master 
GO

DECLARE @mode char(20)
SET @mode = 'MULTI_USER' --SINGLE_USER

DECLARE @t1 TABLE (DatabaseName varchar(50))
INSERT INTO @t1
SELECT name FROM sysdatabases WHERE dbid > 4 
  AND name != 'Dell_Maint'

DECLARE @dbname varchar(50), @SQL varchar (8000)
SET @SQL=''

WHILE EXISTS (SELECT TOP 1 * FROM @t1 t1)
BEGIN
SET @dbname = (SELECT TOP 1 DatabaseName FROM @t1 t1)
SET @SQL='ALTER DATABASE '+(@dbname)+' SET '+@mode
PRINT (@SQL)
--EXEC (@SQL)
DELETE FROM @t1 WHERE DatabaseName = @dbname
END 

--update user mode for a single database
--SELECT name, user_access_desc FROM sys.databases
--ALTER DATABASE database_name SET SINGLE_USER --MULTI_USER