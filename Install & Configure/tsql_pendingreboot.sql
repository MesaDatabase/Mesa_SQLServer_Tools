declare @regLoc varchar(255)
declare @value varchar(255)
set @regLoc='SYSTEM\CurrentControlSet\Control\Session Manager\FileRenameOperations'
set @value = 'PendingFileRenameOperations'

declare @t1 table (Value varchar(255), Data varchar(255))
insert into @t1  
EXEC [master].[dbo].[xp_regread]    @rootkey='HKEY_LOCAL_MACHINE',  
                                    @key=@regLoc,  
                                    @value_name=@value

select @@SERVERNAME as ServerName, @regLoc as RegKey, * from @t1 as t1
                                   