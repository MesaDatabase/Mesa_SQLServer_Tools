set nocount on

declare @t1 table (DatabaseName varchar(50))
insert into @t1
select name from master.dbo.sysdatabases 

create table #t2 (DatabaseName varchar(50), file_name varchar(100), sizeMB decimal(17,2), physical_name varchar(255))
declare @dbname varchar(50), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
set @SQL='insert into #t2 select '''+(@dbname)+''', name, size/128.0, filename from '+@dbname+'.dbo.sysfiles'
--select @SQL
exec (@SQL)
delete from @t1 where DatabaseName = @dbname
end 

select @@servername as server, * from #t2
drop table #t2

