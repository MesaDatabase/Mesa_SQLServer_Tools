
use master
go

set nocount on

declare @db varchar(500)
declare @sql varchar(500)

declare @t1 table (DbId int, DbName varchar(255))
insert into @t1
select database_id, DB_NAME(database_id)
--select *
from sys.databases
where database_id > 4
  and state_desc = 'RESTORING'

while exists (select * from @t1 t1)
begin
	set @db = (select top 1 DbName from @t1 t1)
	set @sql = 'DROP DATABASE [' + @db + '];'
	print(@sql)
	--exec(@sql)

	delete from @t1 where DbName = @db
end	

