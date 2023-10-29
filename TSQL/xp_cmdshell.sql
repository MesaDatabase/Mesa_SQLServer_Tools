--get file name of last backup
declare @t1 table (filename varchar(500))
insert into @t1
exec xp_cmdshell 'dir /B \\SERVER1\D1$\SQLBackup\DBA\SERVER1\db\*.trn'

declare @filename varchar(500)
set @filename = (select top 1 * from @t1 t1 where filename is not null order by 1 desc)

declare @cmd varchar(2000)
set @cmd = 'xcopy \SERVER1\D1$\SQLBackup\DBA\SERVER1\db\' + @filename + ' \\SERVER2\Logshipping'
select @cmd
exec xp_cmdshell @cmd

exec xp_cmdshell '\\SERVER1\D1$\SQLBackup\DBA\SERVER1\db\copy_test.bat'