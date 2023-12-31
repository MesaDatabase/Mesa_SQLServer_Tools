set nocount on

use master

declare @PageSize varchar(10)
select @PageSize=v.low/1024.0
from master..spt_values v
where v.number=1 and v.type='E'

select name as DatabaseName, convert(float,null) as Size
into #tem
From sysdatabases where dbid>4

declare @SQL varchar (8000)
set @SQL=''

while exists (select * from #tem where size is null)
begin
select @SQL='update #tem set size=(select round(sum(size)*'+@PageSize+'/1024,0) From '+quotename(databasename)+'.dbo.sysfiles) where databasename='''+databasename+''''
from #tem
where size is null
exec (@SQL)
end 

select @@servername as server, * from #tem order by DatabaseName
drop table #tem
