set nocount on

declare @t1 table (DatabaseName varchar(100))
insert into @t1
select name from master.dbo.sysdatabases 

create table #t2 (database_name varchar(100), name varchar(100), user_name varchar(255), backup_start_date datetime, backup_finish_date datetime)

declare @dbname varchar(50), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
insert into #t2
select top 1 database_name, name, USER_NAME, backup_start_date, backup_finish_date from msdb.dbo.backupset
where database_name = @dbname
  and type = 'D'
order by backup_start_date desc

delete from @t1 where DatabaseName = @dbname
end 

select @@servername as server, * from #t2
drop table #t2