-----------------------------------------------------------
--Turn mirroring off
--	Run on principal

-----------------------------------------------------------

use master
go

set nocount on

declare @db varchar(500)
declare @sql varchar(500)

declare @t1 table (DbId int, DbName varchar(255))
insert into @t1
select database_id, DB_NAME(database_id)
from sys.database_mirroring
where database_id > 4
  and mirroring_guid is not null
  and mirroring_state_desc = 'SYNCHRONIZED'
  and mirroring_role_desc = 'PRINCIPAL'
order by DB_NAME(database_id)  

while exists (select * from @t1 t1)
begin
	set @db = (select top 1 DbName from @t1 t1)
	set @sql = 'ALTER DATABASE [' + @db + '] SET PARTNER OFF;'
	print(@sql)
	--exec(@sql)

	delete from @t1 where DbName = @db
end	

