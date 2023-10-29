set nocount on

declare @t1 table (DatabaseName varchar(50), Stat tinyint)
insert into @t1
select name, state from sys.databases
where database_id > 4 and name != 'DBA'

create table #t2 (DatabaseName varchar(50), sizeMB decimal(17,4), space_usedMB decimal(17,4))

declare @dbname varchar(50), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1 where Stat = 0)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1 where Stat = 0)
--USE master;
EXEC(N'USE [' + @dbname + N']; EXEC(''insert into #t2 select db_name(),
size/128.0 as SizeMB,
CAST(FILEPROPERTY(name, ''''SpaceUsed'''') AS int)/128.0 as SpaceUsedMB
FROM sys.database_files where type=0;'');');
delete from @t1 where DatabaseName = @dbname
end 

select 
  @@servername as Server, 
  t1.name as DbName,
  t1.database_id as DbId,
  t1.state_desc as [Status],
  t3.name as DbOwner,
  t1.compatibility_level as CompLevel,
  t1.recovery_model_desc as RecoveryModel,
  t1.create_date as CreateDate,
  SUM(sizeMB) as SizeTotalMB,
  SUM(space_usedMB) as UsedTotalMB,
  SUM(sizeMB) - SUM(space_usedMB) as FreeSpaceMB,
  case when sum(space_usedMB) = 0 then 0 else cast(((cast(sum(space_usedMB) as decimal(17,4))/cast(sum(sizeMB) as decimal(17,4)))*100) as decimal(8,4)) end as PctUsed 
from sys.databases as t1
  left join #t2 as t2 on t1.name = t2.DatabaseName
  left join sys.database_principals as t3 on t1.owner_sid = t3.sid
group by
  t1.name,
  t1.database_id,
  t1.state_desc,
  t3.name,
  t1.compatibility_level,
  t1.recovery_model_desc,
  t1.create_date
order by t1.name
drop table #t2

--select * from sys.database_principals 
--select * from sys.databases 
