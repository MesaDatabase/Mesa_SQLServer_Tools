set nocount on

declare @db varchar(255)
declare @t1 table (DbName varchar(255))
declare @logfileid tinyint
declare @sql varchar(2000)

insert into @t1
select name from sys.databases
where database_id > 4
  and name <> 'DBAUtility'
  and state_desc = 'ONLINE'

while exists (select top 1 * from @t1 as t1)
begin
  set @db = (select top 1 DbName from @t1 as t1)
  set @logfileid = (select file_id from sys.database_files where type = 1)
  set @sql = 'use [' + @db + ']; dbcc shrinkfile(' + cast(@logfileid as varchar(4)) + ');'
  print @sql
  exec(@sql)
  delete from @t1 where DbName = @db
end