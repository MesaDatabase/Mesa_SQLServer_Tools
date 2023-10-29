select * from [dbo].[DBUpgradeHistory]

delete from DBUpgradeHistory
where DbVersion = 163

select * from [dbo].[ServerUpgradeHistory]

delete from [ServerUpgradeHistory]
where ServerVersion = 163

SELECT @@version, SERVERPROPERTY('productversion'), SERVERPROPERTY ('productlevel'), SERVERPROPERTY ('edition')

EXEC sp_dbcmptlevel ReportServer, 90; GO EXEC sp_dbcmptlevel ReportServerTempDB, 90; 

select * from sys.databases
where name like 'SSRSServer%'