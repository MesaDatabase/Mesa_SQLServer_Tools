
select * from msdb.dbo.sysmail_account
select * from msdb.dbo.sysmail_profile
select * from msdb.dbo.sysmail_server

select * from msdb.dbo.sysmail_allitems order by send_request_date desc
select * from msdb.dbo.sysmail_event_log order by log_date desc

select * from msdb.[sys].[event_notifications]
select * from msdb.dbo.sysalerts
SELECT * FROM msdb.dbo.sysoperators

[dbo].[sp_help_operator]
[dbo].[sp_help_operator_jobs]
[dbo].[sp_help_alert]
[dbo].[sp_get_job_alerts]

exec sp_notify_operator  
    @profile_name = 'profile' ,  
    @name = 'name' ,  
    @subject = 'Test' ,  
    @body = 'Test' 