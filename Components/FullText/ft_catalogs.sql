set nocount on

declare @t1 table (DatabaseName varchar(100))
insert into @t1
select name from master.dbo.sysdatabases 

create table #t2 (DatabaseName varchar(100), FTName varchar(100))

declare @dbname varchar(100), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
--USE master;
EXEC(N'USE [' + @dbname + N']; EXEC(''insert into #t2 select db_name(), name
FROM sys.fulltext_catalogs;'');');
delete from @t1 where DatabaseName = @dbname
end 

select *
from #t2
drop table #t2

--select * from sys.fulltext_catalogs