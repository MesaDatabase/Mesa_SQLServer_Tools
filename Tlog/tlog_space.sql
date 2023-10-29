set nocount on

declare @temp table (ServerName varchar(100), DbName varchar(100), LogSizeMb decimal(17,2), LogSpaceUsedPct decimal(17,2), Status int)
insert into @temp (DbName, LogSizeMb, LogSpaceUsedPct, [Status])
EXEC('DBCC SQLPERF(LOGSPACE) with NO_INFOMSGS')

update @temp
set ServerName = @@servername

select * from @temp temp
--where LogSpaceUsedPct >= 90

--select top 10 * from sys.dm_db_log_space_usage