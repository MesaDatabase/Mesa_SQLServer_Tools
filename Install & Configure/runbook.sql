--run in query analyzer
--set output to text (control t)
--Make sure output is in Tab delimited format
--Save output in a textfile
use master
go
select 'Servername:'
select @@servername
go
select 'Current Versioning'
select @@Version
go
DECLARE @test varchar(15),@value_name varchar(15),@RegistryPath varchar(200)

IF (charindex('\',@@SERVERNAME)<>0) -- Named Instance
BEGIN
 SET @RegistryPath = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + RIGHT(@@SERVERNAME,LEN(@@SERVERNAME)-CHARINDEX('\',@@SERVERNAME)) + '\MSSQLServer\SuperSocketNetLib\Tcp'
END
ELSE -- Default Instance 
BEGIN
  SET @RegistryPath = 'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\SuperSocketNetLib\Tcp'
END

EXEC master..xp_regread @rootkey='HKEY_LOCAL_MACHINE' ,@key=@RegistryPath,@value_name='TcpPort',@value=@test OUTPUT

select 'The Port Number in use for this instance is '+ @test
go
select ' '
go 

select 'License and page file information'
Declare @version varchar(47)
Declare @CDKey varchar(40)
Declare @PageFile varchar(50)
Select @version = @@version

create table #PageFileDetails (data varchar(500))
insert into #PageFileDetails  exec master.dbo.xp_cmdshell 'wmic pagefile list /format:list'
select @PageFile=rtrim(ltrim(data)) from #PageFileDetails where data like 'AllocatedBaseSize%'
drop table #PageFileDetails

If charindex('2000',@version,1)>0 
Begin
EXEC master.dbo.xp_regread @rootkey='HKEY_LOCAL_MACHINE',
@key='SOFTWARE\Microsoft\Microsoft SQL Server\80\Registration',
@value_name='CD_KEY', @Value=@CDKey OUTPUT
SELECT 'SQL 2000' AS SQLVersion,
CONVERT(char(20), SERVERPROPERTY('ServerName')) AS SQL_Service_Name,
@PageFile AS PageFile,
CONVERT(char(50), SERVERPROPERTY('Edition'))AS SQLEdition,
CONVERT(char(20), SERVERPROPERTY('productversion')) AS ProductVersion,
CONVERT(char(20), SERVERPROPERTY('LicenseType'))AS License_Type,
CONVERT(char(20), SERVERPROPERTY('NumLicenses')) AS Number_Of_Licenses,
@CDKey AS CDKey
end

Else If charindex('2008',@version,1)>0 
Begin
EXEC master.dbo.xp_regread @rootkey='HKEY_LOCAL_MACHINE',   
  @key='SOFTWARE\Microsoft\Microsoft SQL Server\100\Tools\Setup', 
  @value_name='ProductID', @value=@CDKey OUTPUT
SELECT 'SQL 2008' AS SQLVersion,
CONVERT(char(20), SERVERPROPERTY('ServerName')) AS SQL_Service_Name,
@PageFile AS PageFile,
CONVERT(char(50), SERVERPROPERTY('Edition'))AS SQLEdition,
CONVERT(char(20), SERVERPROPERTY('productversion')) AS ProductVersion,
CONVERT(char(20), SERVERPROPERTY('LicenseType'))AS License_Type,
CONVERT(char(20), SERVERPROPERTY('NumLicenses')) AS Number_Of_Licenses,
@CDKey AS CDKey
End

Else If charindex('2008 R2',@version,1)>0 
Begin
EXEC master.dbo.xp_regread @rootkey='HKEY_LOCAL_MACHINE',   
  @key='SOFTWARE\Microsoft\Microsoft SQL Server\150\Tools\Setup', 
  @value_name='ProductID', @value=@CDKey OUTPUT
SELECT 'SQL 2008 R2' AS SQLVersion,
CONVERT(char(20), SERVERPROPERTY('ServerName')) AS SQL_Service_Name,
@PageFile AS PageFile,
CONVERT(char(50), SERVERPROPERTY('Edition'))AS SQLEdition,
CONVERT(char(20), SERVERPROPERTY('productversion')) AS ProductVersion,
CONVERT(char(20), SERVERPROPERTY('LicenseType'))AS License_Type,
CONVERT(char(20), SERVERPROPERTY('NumLicenses')) AS Number_Of_Licenses,
@CDKey AS CDKey
End
Else
SELECT @version AS SQLVersion,
CONVERT(char(20), SERVERPROPERTY('ServerName')) AS SQL_Service_Name,
@PageFile AS PageFile,
CONVERT(char(50), SERVERPROPERTY('Edition'))AS SQLEdition,
CONVERT(char(20), SERVERPROPERTY('productversion')) AS ProductVersion,
CONVERT(char(20), SERVERPROPERTY('LicenseType'))AS License_Type,
CONVERT(char(20), SERVERPROPERTY('NumLicenses')) AS Number_Of_Licenses




select 'Database Information'
go
sp_helpdb
go
select 'Configuration Information'
go
sp_configure 'advanced options', 1
go
reconfigure with override
go
sp_configure
go
sp_configure 'advanced options', 0
go
reconfigure with override
go
select 'File Location Information'
go
select fileid, groupid, size, dbid, name, filename from sysaltfiles
go
select 'Login Information'
select * from syslogins
go
use msdb
go
select 'Jobs Information'
select * from sysjobs
go
select 'DTS Packages'
select distinct name, id, versionid, description, createdate, owner from sysdtspackages
go


use master
go
create table #tblInfo
(

	Parameter	varchar(100),
	MinVal		int,
	MaxVal		int,
	configVal	int,
	run_value	int
)
declare @strSQL varchar(4000)

set @strSQL = 'sp_configure ''show advanced options'',1 reconfigure with override'
exec(@strSQL)

insert into #tblInfo exec('sp_configure')

set @strSQL = ' sp_configure ''show advanced options'',0 reconfigure with override'
exec(@strSQL)

delete #tblInfo where Parameter not in('awe enabled','max server memory (MB)','max worker threads','min memory per query (KB)')


select * from #tblInfo -- sp_configure result for selected parameters

drop table #tblInfo

-- Following statement will return version, processor, and total memory. Please refer 
-- column (Name and Character_Value)
exec ('xp_msver ''ProductVersion'', ''ProcessorCount'', ''PhysicalMemory''')

go
--the following gets drive sizes and free space
select 'Drive Sizes'
SET NOCOUNT ON
DECLARE @hr int
DECLARE @fso int
DECLARE @drive char(1)
DECLARE @odrive int
DECLARE @TotalSize varchar(20)
DECLARE @MB bigint ; SET @MB = 1048576
CREATE TABLE #drives (ServerName varchar(15),
drive char(1) PRIMARY KEY,
FreeSpace int NULL,
TotalSize int NULL,
FreespaceTimestamp DATETIME NULL)
INSERT #drives(drive,FreeSpace)
EXEC master.dbo.xp_fixeddrives
EXEC @hr=sp_OACreate 'Scripting.FileSystemObject',@fso OUT
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso
DECLARE dcur CURSOR LOCAL FAST_FORWARD
FOR SELECT drive from #drives
ORDER by drive
OPEN dcur
FETCH NEXT FROM dcur INTO @drive
WHILE @@FETCH_STATUS=0
BEGIN
EXEC @hr = sp_OAMethod @fso,'GetDrive', @odrive OUT, @drive
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso
EXEC @hr = sp_OAGetProperty @odrive,'TotalSize', @TotalSize OUT
IF @hr <> 0 EXEC sp_OAGetErrorInfo @odrive
UPDATE #drives
SET TotalSize=@TotalSize/@MB, ServerName = host_name(), FreespaceTimestamp = (GETDATE())
WHERE drive=@drive
FETCH NEXT FROM dcur INTO @drive
END
CLOSE dcur
DEALLOCATE dcur
EXEC @hr=sp_OADestroy @fso
IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso
SELECT ServerName,
drive,
TotalSize as 'Total(MB)',
FreeSpace as 'Free(MB)',
CAST((FreeSpace/(TotalSize*1.0))*100.0 as int) as 'Free(%)',
FreespaceTimestamp
FROM #drives
ORDER BY drive
DROP TABLE #drives
RETURN
GO

--Get Linked Server Information
select 'Linked Server Information'
use master
SET NOCOUNT ON
DECLARE @this_server VARCHAR(255),
  @server_ct INT,
  @server VARCHAR(255),
     @srvproduct VARCHAR(255),
     @provider VARCHAR(255),
     @datasrc VARCHAR(255),
     @location VARCHAR(255),
     @provstr VARCHAR(255),
     @catalog VARCHAR(255),
  @rpc INT,
  @pub INT,
  @sub INT,
  @dist INT,
  @dpub INT,
  @rpcout INT,
  @dataaccess INT,
  @collationcompatible INT,
  @system INT,
  @userremotecollation INT,
  @lazyschemavalidation INT,
  @collation VARCHAR(255)

CREATE TABLE #outputLog(
   rowId  INT IDENTITY(1, 1),
   outputData VARCHAR(1000))

CREATE TABLE #srvLogin(
   rowId  INT IDENTITY(1, 1),
   linkedServer VARCHAR(255),
   localLogin VARCHAR(255),
   isSelfMapping INT,
   remoteLogin VARCHAR(255))

SELECT @this_server = srvname FROM sysservers WHERE srvid = 0
SELECT @server_ct = 1

WHILE @server_ct <= (SELECT max(srvid) FROM sysservers)
BEGIN
 select 
  @server = srvname,
     @srvproduct = srvproduct,
     @provider = CASE WHEN srvproduct = 'SQL Server' THEN NULL ELSE providername END,
     @datasrc = CASE WHEN srvproduct = 'SQL Server' THEN NULL ELSE datasource END,
     @location = CASE WHEN srvproduct = 'SQL Server' THEN NULL ELSE location END,
     @provstr = CASE WHEN srvproduct = 'SQL Server' THEN NULL ELSE providerstring END,
     @catalog =  CASE WHEN srvproduct = 'SQL Server' THEN NULL ELSE catalog END,
  @rpc = rpc,
  @pub = pub,
  @sub = sub,
  @dist = dist,
  @dpub = dpub,
  @rpcout = rpcout,
  @dataaccess = dataaccess,
  @collationcompatible = collationcompatible,
  @system = system,
  @userremotecollation = useremotecollation,
  @lazyschemavalidation = lazyschemavalidation,
  @collation = collation
 from 
  sysservers
 WHERE 
  srvid = @server_ct

 INSERT INTO #outputLog
 SELECT 'EXEC sp_addlinkedserver ''' + @server + ''', '
   + CASE WHEN @srvproduct IS NULL THEN 'NULL' ELSE '''' + @srvproduct + '''' END + ', '
   + CASE WHEN @provider IS NULL THEN 'NULL' ELSE '''' + @provider + '''' END + ', '
   + CASE WHEN @datasrc IS NULL THEN 'NULL' ELSE '''' + @datasrc + '''' END + ', '
   + CASE WHEN @location IS NULL THEN 'NULL' ELSE '''' + @location + '''' END + ', '
   + CASE WHEN @provstr IS NULL THEN 'NULL' ELSE '''' + @provstr + '''' END + ', '
   + CASE WHEN @catalog IS NULL THEN 'NULL' ELSE '''' + @catalog + '''' END

 INSERT INTO #outputLog
 SELECT 'EXEC sp_serveroption ''' + @server + ''', ''' + 'rpc'', ' + CASE WHEN @rpc = 1 THEN '''TRUE''' ELSE '''FALSE''' END 

 INSERT INTO #outputLog
 SELECT 'EXEC sp_serveroption ''' + @server + ''', ''' + 'pub'', ' + CASE WHEN @pub = 1 THEN '''TRUE''' ELSE '''FALSE''' END 

 INSERT INTO #outputLog
 SELECT 'EXEC sp_serveroption ''' + @server + ''', ''' + 'sub'', ' + CASE WHEN @sub = 1 THEN '''TRUE''' ELSE '''FALSE''' END 

 INSERT INTO #outputLog
 SELECT 'EXEC sp_serveroption ''' + @server + ''', ''' + 'dist'', ' + CASE WHEN @dist = 1 THEN '''TRUE''' ELSE '''FALSE''' END 

 INSERT INTO #outputLog
 SELECT 'EXEC sp_serveroption ''' + @server + ''', ''' + 'dpub'', ' + CASE WHEN @dpub = 1 THEN '''TRUE''' ELSE '''FALSE''' END 

 INSERT INTO #outputLog
 SELECT 'EXEC sp_serveroption ''' + @server + ''', ''' + 'rpc out'', ' + CASE WHEN @rpcout = 1 THEN '''TRUE''' ELSE '''FALSE''' END 

 INSERT INTO #outputLog
 SELECT 'EXEC sp_serveroption ''' + @server + ''', ''' + 'data access'', ' + CASE WHEN @dataaccess = 1 THEN '''TRUE''' ELSE '''FALSE''' END 

 INSERT INTO #outputLog
 SELECT 'EXEC sp_serveroption ''' + @server + ''', ''' + 'collation compatible'', ' + CASE WHEN @collationcompatible = 1 THEN '''TRUE''' ELSE '''FALSE''' END 

--  INSERT INTO #outputLog
--  SELECT 'EXEC sp_serveroption ''' + @server + ''', ''' + 'system'', ' + CASE WHEN @system = 1 THEN '''TRUE''' ELSE '''FALSE''' END 

 INSERT INTO #outputLog
 SELECT 'EXEC sp_serveroption ''' + @server + ''', ''' + 'use remote collation'', ' + CASE WHEN @userremotecollation = 1 THEN '''TRUE''' ELSE '''FALSE''' END 

 INSERT INTO #outputLog
 SELECT 'EXEC sp_serveroption ''' + @server + ''', ''' + 'lazy schema validation'', ' + CASE WHEN @lazyschemavalidation = 1 THEN '''TRUE''' ELSE '''FALSE''' END 

--  INSERT INTO #outputLog
--  SELECT 'EXEC sp_serveroption ''' + @server + ''', ''' + 'collation'', ' + CASE WHEN @collation IS NULL THEN 'NULL' ELSE '''' + @collation + '''' END + '' 

 INSERT INTO #srvLogin
 EXEC sp_helplinkedsrvlogin @server

 INSERT INTO #outputLog
 SELECT 'EXEC sp_addlinkedsrvlogin @rmtsrvname = '+ CASE WHEN linkedServer IS NULL THEN 'NULL' ELSE '''' + linkedServer + '''' END
   + ', @useself = ' + CASE WHEN isSelfMapping = 1 THEN '''TRUE''' ELSE '''FALSE''' END 
   + ', @locallogin = ' + CASE WHEN localLogin IS NULL THEN 'NULL' ELSE '''' + localLogin + '''' END 
   + ', @rmtuser = ' + CASE WHEN remoteLogin IS NULL THEN 'NULL' ELSE '''' + remoteLogin + '''' END
   + ', @rmtpassword  = ' + CASE WHEN isSelfMapping = 1 THEN 'NULL' ELSE '''ENTER_PASSWORD_HERE''' END
   
 FROM  #srvLogin
 
 DELETE #srvLogin

 SELECT @server_ct = @server_ct + 1
END

SELECT outputData from #outputLog
ORDER BY rowId

DROP TABLE #outputLog
DROP TABLE #srvLogin

--END

--security information
select 'Security Information'
select @@Servername


--run in query analyzer
--execute in text file format
--save as a text file.  This script pulls all data for roles and grants from sql and windows.



SET NOCOUNT ON

IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE name = '##Users' AND type in (N'U'))
 DROP TABLE ##Users;
IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE name = '##DBUsers' AND type in (N'U'))
 DROP TABLE ##DBUsers;

-- ***************************************************************************
-- Always run this from master  --Not needed
-- USE master 
-- ***************************************************************************

-- ***************************************************************************
-- Declare local variables
DECLARE @DBName VARCHAR(75);
DECLARE @SQLCmd VARCHAR(1024);
-- ***************************************************************************

-- ***************************************************************************
-- Get the SQL Server logins
-- Create Temp User table
CREATE TABLE ##Users (
[sid] varbinary(100) NULL,
[Login Name] varchar(100) NULL,
[Default Database] varchar(255) NULL,
[Login Type] varchar(15),
[AD Login Type] varchar(25),
[sysadmin] varchar(3),
[securityadmin] varchar(3),
[serveradmin] varchar(3),
[setupadmin] varchar(3),
[processadmin] varchar(3),
[diskadmin] varchar(3),
[dbcreator] varchar(3),
[bulkadmin] varchar(3));
---------------------------------------------------------
INSERT INTO ##Users SELECT sid,
 loginname AS [Login Name], 
 dbname AS [Default Database],
 CASE isntname 
 WHEN 1 THEN 'AD Login'
 ELSE 'SQL Login'
 END AS [Login Type],
 CASE 
 WHEN isntgroup = 1 THEN 'AD Group'
 WHEN isntuser = 1 THEN 'AD User'
 ELSE ''
 END AS [AD Login Type],
 CASE sysadmin
 WHEN 1 THEN 'Yes'
 ELSE 'No'
 END AS [sysadmin],
 CASE [securityadmin]
 WHEN 1 THEN 'Yes'
 ELSE 'No'
 END AS [securityadmin],
 CASE [serveradmin]
 WHEN 1 THEN 'Yes'
 ELSE 'No'
 END AS [serveradmin],
 CASE [setupadmin]
 WHEN 1 THEN 'Yes'
 ELSE 'No'
 END AS [setupadmin],
 CASE [processadmin]
 WHEN 1 THEN 'Yes'
 ELSE 'No'
 END AS [processadmin],
 CASE [diskadmin]
 WHEN 1 THEN 'Yes'
 ELSE 'No'
 END AS [diskadmin],
 CASE [dbcreator]
 WHEN 1 THEN 'Yes'
 ELSE 'No'
 END AS [dbcreator],
 CASE [bulkadmin]
 WHEN 1 THEN 'Yes'
 ELSE 'No'
 END AS [bulkadmin]
FROM master.dbo.syslogins;
---------------------------------------------------------
SELECT [Login Name],
 [Default Database], 
 [Login Type],
 [AD Login Type],
 [sysadmin],
 [securityadmin],
 [serveradmin],
 [setupadmin],
 [processadmin],
 [diskadmin],
 [dbcreator],
 [bulkadmin]
FROM ##Users
ORDER BY [Login Type], [AD Login Type], [Login Name]
-- ***************************************************************************
-- ***************************************************************************
-- Create the output table for the Database User ID's
CREATE TABLE ##DBUsers (
 [Database User ID] VARCHAR(100),
 [Server Login] VARCHAR(100),
 [Database Role] VARCHAR(160),
 [Database] VARCHAR(200));
-- ***************************************************************************
-- ***************************************************************************
-- Declare a cursor to loop through all the databases on the server
DECLARE csrDB CURSOR FOR 
 SELECT name
 FROM master..sysdatabases
 WHERE name NOT IN ('master', 'model', 'msdb', 'tempdb');
-- ***************************************************************************
-- ***************************************************************************
-- Open the cursor and get the first database name
OPEN csrDB
FETCH NEXT 
 FROM csrDB
 INTO @DBName
-- ***************************************************************************
-- ***************************************************************************
-- Loop through the cursor
WHILE @@FETCH_STATUS = 0
 BEGIN
-- ***************************************************************************
-- ***************************************************************************
-- 
 SELECT @SQLCmd = 'INSERT ##DBUsers ' +
 ' SELECT su.[name] AS [Database User ID], ' +
 ' COALESCE (u.[Login Name], ''** Orphaned **'') AS [Server Login], ' +
 ' COALESCE (sug.name, ''Public'') AS [Database Role],' + 
 '''' + @DBName + ''' AS [Database]' +
 ' FROM [' + @DBName + '].[dbo].[sysusers] su' +
 ' LEFT OUTER JOIN ##Users u' +
 ' ON su.sid = u.sid' +
 ' LEFT OUTER JOIN ([' + @DBName + '].[dbo].[sysmembers] sm ' +
 ' INNER JOIN [' + @DBName + '].[dbo].[sysusers] sug ' +
 ' ON sm.groupuid = sug.uid)' +
 ' ON su.uid = sm.memberuid ' +
 ' WHERE su.hasdbaccess = 1' +
 ' AND su.[name] != ''dbo'' '
 EXEC (@SQLCmd)
-- ***************************************************************************
-- ***************************************************************************
-- Get the next database name
 FETCH NEXT 
 FROM csrDB
 INTO @DBName
-- ***************************************************************************
-- ***************************************************************************
-- End of the cursor loop
 END
-- ***************************************************************************
-- ***************************************************************************
-- Close and deallocate the CURSOR
CLOSE csrDB
DEALLOCATE csrDB
-- ***************************************************************************
-- ***************************************************************************
-- Return the Database User data
SELECT * 
 FROM ##DBUsers
 ORDER BY [Database User ID],[Database];
-- ***************************************************************************
-- ***************************************************************************
-- Clean up - delete the Global temp tables
IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE name = '##Users' AND type in (N'U'))
 DROP TABLE ##Users;

IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE name = '##DBUsers' AND type in (N'U'))
 DROP TABLE ##DBUsers;
-- ***************************************************************************

GO
--this code pulls all items from the windows admin security group
select 'Windows Administrator Group'
EXEC master..xp_cmdshell 'net localgroup administrators'
go

--pull sql server logins and check for null passwords
--accounts null have no password encryption
select 'SQL Server Accounts/Passwords'
select 'Note:  Anything with no encrypted password needs attention'
select name, password from syslogins
where isntgroup=0 and isntuser=0
go

--sp_help_revlogin output
--Note:  This may not exist in master but if it does--output will be created
--use master
--go
--exec sp_help_revlogin

--this section takes an excerpt of the past 7 days
select 'Backup Report For Past 7 Days'
use msdb
go
select database_name, name, type, backup_finish_date from backupset
where (type='D' or type='I')
and backup_finish_date > getdate()-7
