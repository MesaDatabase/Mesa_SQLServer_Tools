set nocount on

declare @sql varchar(4000)
declare @fname varchar(1000)

declare @temp table (filename varchar(1000))
insert into @temp
exec xp_cmdshell 'dir /B /OD H:\Migration\EmailPreferences\*.trn'
  
delete from @temp
where filename is null

while exists (select top 1 * from @temp t1)
begin
  set @fname = (select top 1 filename from @temp t1)
  set @sql = 'restore database EmailPreferences from disk = ''H:\Migration\EmailPreferences\' + @fname + ''' with norecovery'
  print @sql
  delete from @temp where filename = @fname
end
  