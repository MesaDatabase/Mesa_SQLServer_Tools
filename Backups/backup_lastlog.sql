set nocount on

declare @t1 table (DatabaseName varchar(50))
insert into @t1
select name from master.dbo.sysdatabases 
--where name = 'tempdb'
where dbid>4 and name != 'dbname'

create table #t2 (DatabaseName varchar(50), backup_start_date datetime, backup_finish_date datetime)

declare @dbname varchar(50), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
  set @dbname = (select top 1 DatabaseName from @t1 t1)
  insert into #t2
  select top 1 @dbname, backup_start_date, backup_finish_date 
  from msdb.dbo.backupset (nolock)
  where database_name = @dbname
    and type = 'L'
  order by backup_start_date desc 
delete from @t1 where DatabaseName = @dbname
end 

select @@servername, t2.*, s1.* from #t2 as t2
  right join sys.databases as s1 on t2.DatabaseName = s1.name
where s1.recovery_model_desc = 'FULL'
  and s1.database_id > 4
drop table #t2

