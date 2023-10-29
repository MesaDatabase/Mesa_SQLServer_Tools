
use master
go

set nocount on

declare @db varchar(500)
declare @sql varchar(500)

declare @t1 table (DbId int, DbName varchar(255))
insert into @t1
select database_id, name
--select *
from sys.databases
where database_id > 4
  and state_desc = 'ONLINE'
  and page_verify_option_desc != 'CHECKSUM'
order by name

while exists (select * from @t1 t1)
begin
	set @db = (select top 1 DbName from @t1 t1)
	set @sql = 'ALTER DATABASE [' + @db + '] SET PAGE_VERIFY CHECKSUM  WITH NO_WAIT;'
	print(@sql)
	--exec(@sql)

	delete from @t1 where DbName = @db
end	
