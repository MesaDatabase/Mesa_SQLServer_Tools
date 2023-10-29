---offline all user databases on this server

--get list of user databases on this server
declare @userdbs table (DbName varchar(255))
insert into @userdbs
select name from sys.databases
where name not in ('master','msdb','model','tempdb')
and state_desc = 'ONLINE'

declare @sql varchar(4000)
declare @db varchar(255)

--loop thru list of databases
while exists (select 1 from @userdbs)
--set database offline & remove from list
begin
  set @db = (select top 1 DbName from @userdbs)
  set @sql = 'ALTER DATABASE ' + @db + ' SET OFFLINE'
  exec(@sql)
  delete from @userdbs where DbName = @db
end