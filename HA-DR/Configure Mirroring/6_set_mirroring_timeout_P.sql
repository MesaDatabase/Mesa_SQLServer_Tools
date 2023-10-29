-----------------------------------------------------------
--Configure mirroring session timeout on PTC-C
--		MULTI-SERVER (exclude REPORTSELF)
--		Run on PTC-C
--		Prior to Script Use: In SSMS, go to Tools -> Options -> Query Results -> SQL Server -> Multiserver Result
--			Set "Add server name to the results" to "False"
-----------------------------------------------------------

--validate that mirroring sessions are synchronized, check timeout value
select 
  @@servername, db_name(database_id), database_id, mirroring_state_desc, mirroring_role_desc, 
  mirroring_safety_level_desc, mirroring_connection_timeout
from sys.database_mirroring where mirroring_guid is not null

--configure mirroring session timeout to 60 seconds
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
	set @sql = 'ALTER DATABASE [' + @db + '] SET PARTNER TIMEOUT 60;'
	--print(@sql)
	exec(@sql)

	delete from @t1 where DbName = @db
end	


--validate that mirroring sessions are synchronized, check timeout value
select 
  @@servername, db_name(database_id), database_id, mirroring_state_desc, mirroring_role_desc, 
  mirroring_safety_level_desc, mirroring_connection_timeout
from sys.database_mirroring where mirroring_guid is not null