--.net framework version
declare @regLoc varchar(255)
declare @value varchar(255)
set @regLoc='SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727'
set @value = 'Increment'

declare @t1 table (Value varchar(255), Data varchar(255))
insert into @t1  
EXEC [master].[dbo].[xp_regread]    @rootkey='HKEY_LOCAL_MACHINE',  
                                    @key=@regLoc,  
                                    @value_name=@value

select @@SERVERNAME as ServerName, @regLoc as RegKey, * from @t1 as t1
                                   


--powershell version
declare @regLoc varchar(255)
declare @value varchar(255)
set @regLoc='SOFTWARE\Microsoft\Powershell\1\PowerShellEngine'
set @value = 'PowerShellVersion'

declare @t1 table (Value varchar(255), Data varchar(255))
insert into @t1  
EXEC [master].[dbo].[xp_regread]    @rootkey='HKEY_LOCAL_MACHINE',  
                                    @key=@regLoc,  
                                    @value_name=@value

select @@SERVERNAME as ServerName, @regLoc as RegKey, * from @t1 as t1
                                   