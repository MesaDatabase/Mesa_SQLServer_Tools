set nocount on

declare @t1 table (DatabaseName varchar(50))
insert into @t1
select name from master.dbo.sysdatabases 
where name not in ('master','model','msdb')

create table #t2 (FileId int, FileSize bigint, StartOffset bigint, FSeqNo bigint, Status int, Parity int, CreateLSN varchar(50))
create table #t3 (DatabaseName varchar(50), FileId int, FileSize bigint, StartOffset bigint, FSeqNo bigint, Status int, Parity int, CreateLSN varchar(50))

declare @dbname varchar(50), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
set @SQL='DBCC LOGINFO (' + @dbname + ') WITH TABLERESULTS, NO_INFOMSGS'

insert into #t2
exec(@SQL)
insert into #t3 select @dbname, * from #t2

delete from @t1 where DatabaseName = @dbname
delete from #t2
end 

select
DatabaseName, count(1)
from #t3
group by DatabaseName
order by count(1) desc

drop table #t2
drop table #t3