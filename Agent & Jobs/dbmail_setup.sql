EXEC sp_Configure 'Database Mail XPs', 1
GO

RECONFIGURE
GO

-- Create a Database Mail account
EXEC msdb.dbo.sysmail_add_account_sp
      @account_name = 'DB Mail'
    , @email_address = 'monitoring@email.com'
    , @description = 'Database Mail Account'
    , @mailserver_name = '155.16.59.115'
    , @port = 25
    , @username = 'domain\ProcessName'
    , @password = <pwd>

-- Create a Database Mail profile
EXECUTE msdb.dbo.sysmail_add_profile_sp
    @profile_name = 'DBMailProfile',
    @description = 'Profile for DB Mail';

-- Add the account to the profile
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'DBMailProfile',
    @account_name = 'DB Mail',
    @sequence_number = 1;

--test mail
EXECUTE msdb.dbo.sp_send_dbmail
	@profile_name = 'UFCUDB',
    @subject = 'Test Database Mail Message',
	@recipients = 'recipient@domain.com',
    @query = 'set nocount on;SELECT Getdate() as ServerTime';


--view mail setup
select * from msdb.dbo.sysmail_account
select * from msdb.dbo.sysmail_profile

--delete account/profile
--exec msdb.dbo.sysmail_delete_account_sp @account_name = 'MyMailAccount'
--exec msdb.dbo.sysmail_delete_profile_sp @profile_name = 'MyPublicProfile'


--set up operator
USE [msdb]
GO

/****** Object:  Operator [Alerts_Operator]    Script Date: 10/10/2012 1:50:16 PM ******/
EXEC msdb.dbo.sp_add_operator @name=N'Alerts_Operator', 
		@enabled=1, 
		@weekday_pager_start_time=0, 
		@weekday_pager_end_time=235959, 
		@saturday_pager_start_time=0, 
		@saturday_pager_end_time=235959, 
		@sunday_pager_start_time=0, 
		@sunday_pager_end_time=235959, 
		@pager_days=127, 
		@email_address=N'email@email.com', 
		@category_name=N'[Uncategorized]'
GO

--test email to operator
USE msdb ;
GO

EXEC dbo.sp_notify_operator
   @profile_name = N'DBMailProfile',
   @name = N'Alerts_Operator',
   @subject = N'Test Notification',
   @body = N'This is a test of notification via e-mail.' ;
GO


--db mail objects
select * from msdb.sys.objects
where (name like '%mail%')
  and type in ('U','V','F','P')
  
select * from msdb.dbo.sysmail_account
select * from msdb.dbo.sysmail_profile
select * from msdb.dbo.sysmail_server
select * from msdb.dbo.sysmail_log
select * from msdb.dbo.sysmail_allitems order by send_request_date desc
select * from msdb.dbo.sysmail_sentitems
select * from msdb.dbo.sysmail_unsentitems where mailitem_id = 856
select * from msdb.dbo.sysmail_faileditems
select * from msdb.dbo.sysmail_mailitems
select * from msdb.dbo.sysmail_event_log order by log_date desc
SELECT is_broker_enabled FROM sys.databases WHERE name = 'msdb' 

EXEC msdb.dbo.sysmail_help_queue_sp @queue_type = 'mail';
EXEC msdb.dbo.sysmail_help_status_sp
EXEC msdb.dbo.sysmail_stop_sp
EXEC msdb.dbo.sysmail_start_sp

EXEC  msdb.dbo.sysmail_delete_mailitems_sp
      @sent_before = '2013-05-02 00:00:00', 
      @sent_status = 'failed' 

select * from sys.dm_broker_queue_monitors 
select * from sys.service_queues

--update dbmail attachment size
EXECUTE msdb.dbo.sysmail_configure_sp 'MaxFileSize', '10000000';


--for users that own jobs that need to use db mail profile
---add to DatabaseMailUserRole, dbreader, and all 3 SQL Agent roles
---grant execute on sp_send_dbmail
---and add permission for them to use the profile
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = 'General Admin Mail',
    @principal_name = 'TestUser',
    @is_default = 1 ;


--confirm db mail is started
EXEC msdb.dbo.sysmail_help_status_sp;

--if db mail activation is not stared, start it with
EXEC msdb.dbo.sysmail_start_sp;

--check status of mail queue
EXEC msdb.dbo.sysmail_help_queue_sp @queue_type = 'mail';

--stop db mail
EXEC msdb.dbo.sysmail_stop_sp;

--check event log
SELECT * FROM msdb.dbo.sysmail_event_log;
