-----------------------------------------------------------
--Configure mirroring on mirror
--		Prior to Script Use: In SSMS, go to Tools -> Options -> Query Results -> SQL Server -> Multiserver Result
--			Set "Add server name to the results" to "False"
-----------------------------------------------------------


--configure mirroring on mirror
use master
go

set nocount on

declare @db varchar(500)
declare @sql varchar(500)
declare @partner varchar(25)

declare @t1 table (DbId int, DbName varchar(255), PartnerInst varchar(25))
insert into @t1
select database_id, name, 'SERVER1'
--select *
from sys.databases as s1
where s1.database_id > 4
  and s1.name not in ('DBA')

while exists (select * from @t1 t1)
begin
	set @db = (select top 1 DbName from @t1 t1)
	set @partner = (select top 1 PartnerInst from @t1 t1 where DbName = @db)
	set @sql = 'ALTER DATABASE [' + @db + '] SET PARTNER = ''TCP://' + @partner + '.ufcunet.ad:5022'';'
	print(@sql)
	--exec(@sql)

	delete from @t1 where DbName = @db
end	



