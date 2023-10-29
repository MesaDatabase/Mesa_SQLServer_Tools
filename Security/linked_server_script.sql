declare
    @status	    smallint,	     -- server status
    @server         sysname,         -- server name
    @srvid	    smallint,	     -- server id
    @srvproduct     nvarchar(128),   -- product name (dflt to ss)
    @allsetopt      int,	     --sum of all settable options
    @provider       nvarchar(128),   -- oledb provider name
    @datasrc        nvarchar(4000),  -- oledb datasource property
    @location       nvarchar(4000),  -- oledb location property
    @provstr        nvarchar(4000),  -- oledb provider-string property
    @catalog        sysname,         -- oledb catalog property
    @netname	    varchar(30),     -- Server net name
    @srvoption	    varchar(30),     -- server options
    @loclogin       varchar(30),     -- Local user
    @rmtlogin       varchar(30),     -- Remote user
    @selfstatus     smallint,	     -- linked server login status
    @rmtpass        varbinary(256),  -- linked server login password
    @pwdtext        nvarchar(128),   -- linked server decrypted password
    @i              int,             -- linked server pswd decrypt var
    @lsb            tinyint,         -- linked server pswd decrypt var
    @msb            tinyint,         -- linked server pswd decrypt var
    @tmp            varbinary(256)   -- linked server pswd decrypt var

select @allsetopt=number from master.dbo.spt_values
		where type = 'A' and name = 'ALL SETTABLE OPTIONS'  -- Only 7.0 else use 4063
    
declare d cursor for SELECT srvid,srvstatus, srvname, srvproduct, providername, datasource,
	location, providerstring, catalog, srvnetname 
	from master..sysservers
	where srvid > 0  -- Local Server
open d   
   fetch next from d into @srvid, @status, @server, @srvproduct, @provider, @datasrc,
	@location, @provstr, @catalog, @netname
SET NOCOUNT  ON	
	
while (@@FETCH_STATUS<>-1) begin
   
PRINT '--------------------------------'
Print '--      ' + @server
PRINT '--------------------------------'   
If @status in (64,65)               --Remote Server
Begin
	Print 'sp_addserver'
	Print '  @server = '''+ @server + ''''
	Print '  GO'
		
	If @status = 64
	Begin
		Print 'sp_serveroption'
		Print '  @server = '''+ @server + ''','
		Print '  @optname = ''rpc'','
		Print '  @optvalue = ''false'''
		Print '  GO'
	End
	exec ('declare  r cursor for
	select l.name, r.remoteusername from 
	sysremotelogins r join sysservers s on
	r.remoteserverid = s.srvid
	join syslogins l on
	r.sid = l.sid
	where s.srvname = '''+ @server + '''')
	open r
		fetch next from r into @loclogin, @rmtlogin
	while (@@FETCH_STATUS<>-1)
	begin
	Print 'sp_addremotelogin'
	Print '  @remoteserver = '''+ @server + ''','
	Print '  @loginame  = '''+ @loclogin + ''','
	Print '  @remotename = '''+ @rmtlogin + ''''
	Print '  GO'
		fetch next from r into @loclogin, @rmtlogin
	end
	close r
	deallocate r
	
	
End
Else   --Linked server
Begin
	If exists (select * from tempdb..sysobjects where name like '#tmpsrvoption%')
	Begin
	drop table #tmpsrvoption
	End

	Create Table #tmpsrvoption
	(
	srvoption  varchar(30)
	)
	insert #tmpsrvoption
	select v.name
		from master.dbo.spt_values v, master.dbo.sysservers s
		where srvid = @srvid
			and (v.number & s.srvstatus)=v.number
			and (v.number & isnull(@allsetopt,4063)) <> 0 
			and v.number not in (-1, isnull(@allsetopt,4063))
			and v.type = 'A'

	PRINT 'sp_addlinkedserver'
	Print '  @server = '''+ @server + ''''
	Print ',  @srvproduct = ''' + @srvproduct + ''''
	If @srvproduct <> 'SQL Server'   --Cannot specify additional info for SQL Server Product
	Begin
		Print ',  @provider = ''' + @provider + ''''
		Print ',  @datasrc = ''' + @datasrc + ''''
		Print ',  @location = ''' + @location + ''''
		Print ',  @provstr = ''' + @provstr + '''' 
		Print ',  @catalog = ''' + @catalog + ''''
	End
		Print '  GO'
			   
	-- Set all servers options to false, then reset correct server options
	Print 'sp_serveroption'
		Print '  @server = '''+ @server + ''','
		Print '  @optname = ''rpc'','
		Print '  @optvalue = ''false'''
		Print '  GO'
	Print 'sp_serveroption'
		Print '  @server = '''+ @server + ''','
		Print '  @optname = ''rpc out'','
		Print '  @optvalue = ''false'''
		Print '  GO'
	Print 'sp_serveroption'
		Print '  @server = '''+ @server + ''','
		Print '  @optname = ''data access'','
		Print '  @optvalue = ''false'''
		Print '  GO'
		
	declare s cursor for SELECT srvoption
	from #tmpsrvoption
	
	open s  
   	fetch next from s into @srvoption
	
	while (@@FETCH_STATUS<>-1)
	begin
		Print 'sp_serveroption'
		Print '  @server = '''+ @server + ''','
		Print '  @optname = '''+ @srvoption + ''','
		Print '  @optvalue = ''true'''
		Print '  GO'

		fetch next from s into @srvoption
	End
	close s
	deallocate s
	

--Script linked server logins
If exists (select * from tempdb..sysobjects where name like '#tmplink%')
	Begin
	drop table #tmplink
	End

create table #tmplink
(
rmtserver sysname,
loclogin sysname null,
selfstatus smallint,
rmtlogin sysname null
)

insert #tmplink
exec ('sp_helplinkedsrvlogin '''+ @server + '''')

declare ll cursor for
select loclogin, selfstatus, rmtlogin from #tmplink order by rmtlogin

open ll
fetch next from ll into @loclogin, @selfstatus, @rmtlogin

while (@@FETCH_STATUS<>-1)
begin
    -- Use self no remote user/password
If (@selfstatus = 1 and @loclogin is null)
Begin
	Print 'sp_addlinkedsrvlogin'
	Print '  @rmtsrvname = '''+ @server + ''','
	Print '  @useself = ''true'''
	Print '  GO'
End
Else
If (@selfstatus = 1 and @loclogin is not null) Begin
Print 'sp_addlinkedsrvlogin'
	Print '  @rmtsrvname = '''+ @server + ''','
	Print '  @useself = ''true'','
	Print '  @locallogin = '''+ @loclogin + ''','
	Print '  @rmtuser = NULL,'
	Print '  @rmtpassword = NULL'
	Print '  GO'
End
Else
If (@selfstatus = 0 and @rmtlogin is null) Begin
Print 'sp_addlinkedsrvlogin'
	Print '  @rmtsrvname = '''+ @server + ''','
	Print '  @useself = ''false'','
	Print '  @locallogin = NULL,'
	Print '  @rmtuser = NULL,'
	Print '  @rmtpassword = NULL'
	Print '  GO'
End
Else
If (@selfstatus = 0) Begin  -- Check for Use self mappings
	exec ('declare pwd cursor for
	select l.password from master..sysservers s
	join master..sysxlogins l on s.srvid = l.srvid --where l.sid is not null
	where s.srvname = '''+ @server + ''' and l.name = '''+ @rmtlogin + '''')
-- Decrypt passwords
-- Only works for 7.0 server
-- Encrypt algorithm changed in 2000
	open pwd
	fetch next from pwd into @rmtpass
	while @@fetch_status = 0
    	begin
    	set @i = 0
    	set @pwdtext = N''
    	while @i < datalength(@rmtpass)
        begin
        set @tmp = encrypt(@pwdtext + nchar(0))
        set @lsb = convert(tinyint, substring(@tmp, @i + 1, 1))
            ^ convert(tinyint, substring(@rmtpass, @i + 1, 1))
        set @i = @i + 1

        set @tmp = encrypt(@pwdtext + nchar(@lsb))
        set @msb = convert(tinyint, substring(@tmp, @i + 1, 1))
            ^ convert(tinyint, substring(@rmtpass, @i + 1, 1))
        set @i = @i + 1

        set @pwdtext = @pwdtext + nchar(convert(smallint, @lsb)
            + 256 * convert(smallint, @msb))
        end

    	Print 'sp_addlinkedsrvlogin'
	Print '  @rmtsrvname = '''+ @server + ''','
	Print '  @useself = ''false'','
	If (@loclogin is null)
	Begin
		Print '  @locallogin = NULL,'
	End
	Else
		Begin
			Print '  @locallogin = '''+ @loclogin + ''','
		End
	If (@rmtlogin is null)
	Begin
		Print '  @rmtuser = NULL,'
	End
	Else
		Begin
			Print '  @rmtuser = '''+ @rmtlogin + ''','
		End
	If (@pwdtext is null)
	Begin
		Print '  @rmtpassword = NULL'
	End
	Else
		Begin
			print '  @rmtpassword = '''+ @pwdtext + ''''
		End
	Print '  GO'

    	fetch next from pwd into @rmtpass
    end
    close pwd	
    deallocate pwd
End
	fetch next from ll into @loclogin, @selfstatus, @rmtlogin

End
close ll	
deallocate ll
	
	
	
End
If @netname <> @server   -- If the srvnetname.sysservers is different from srvname.sysservers
	Begin
		Print 'sp_setnetname'
		Print '  @server = '''+ @server + ''','
		Print '  @network_name = '''+ @netname + ''''
	End

fetch next from d into @srvid,@status, @server, @srvproduct, @provider, @datasrc,
	@location, @provstr, @catalog, @netname
	
End
close d
deallocate d




