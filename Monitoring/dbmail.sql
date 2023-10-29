
-- Create a Database Mail account
EXEC msdb.dbo.sysmail_add_account_sp
      @account_name = 'MyMailAccount'
    , @email_address = 'me@gmail.com'
    , @display_name = 'My Servers Database Mail Account'
    , @description = 'MyMailAccount'
    , @mailserver_name = 'smtp.gmail.com'
    , @port = 587
    , @username = 'me@gmail.com'
    , @password = 'mYpASSWORD'
    , @enable_ssl = 1

-- Create a Database Mail profile
EXECUTE msdb.dbo.sysmail_add_profile_sp
    @profile_name = 'MyPublicProfile',
    @description = 'My Public Profile';

-- Add the account to the profile
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'MyPublicProfile',
    @account_name = 'MyMailAccount',
    @sequence_number = 1;

-- Configuring global profile, and setting default mail profile
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = 'MyPublicProfile',
    @principal_name = 'public',
    @is_default = 1;
GO


--test mail
EXECUTE msdb.dbo.sp_send_dbmail
	@profile_name = 'DBMailProfile'
    @subject = 'New User Created',
    @recipients = 'renee_jaramillo@dell.com'


declare @cnt int

set @cnt = (select count(1) from CMCDB_PROD.dbo.UserAcct where CreateDate >= dateadd(hh,-10,getutcdate()))

if @cnt > 0
  begin
    exec msdb.dbo.sp_send_dbmail
		@profile_name = 'DBMailProfile',
		@subject = 'New User Created',
		@recipients = 'renee_jaramillo@dell.com;vipin_kalra@dell.com';
  end

--view mail setup
exec msdb.dbo.sysmail_delete_account_sp @account_name = 'MyMailAccount'
exec msdb.dbo.sysmail_delete_profile_sp @profile_name = 'MyPublicProfile'

select * from msdb.dbo.sysmail_account
select * from msdb.dbo.sysmail_profile


