--Connect to the job database specified when creating the job agent

---- Add a job to collect perf results
--EXEC jobs.sp_add_job @job_name ='ElasticPoolPerfMetrics', @description='Collect elastic pool performance data'

---- Add a job step w/ schedule to collect results
--EXEC jobs.sp_add_jobstep
--@job_name='ElasticPoolPerfMetrics',
--@command= N' SELECT DB_NAME() DatabaseName, $(job_execution_id) AS job_execution_id, * FROM sys.dm_db_resource_stats WHERE end_time > DATEADD(mi, -20, GETDATE());',
--@credential_name='jobcred',
--@target_group_name='NonProdGroup1',
--@output_type='SqlDatabase',
--@output_credential_name='jobcred',
--@output_server_name='dbsrv.database.windows.net',
--@output_database_name='dbsrverdb',
--@output_table_name='Stats_ElasticPools'

--Create a job to monitor pool performance
--Connect to the job database specified when creating the job agent

---- Add a target group containing master database
--EXEC jobs.sp_add_target_group 'MasterGroup'

---- Add a server target member
--EXEC jobs.sp_add_target_group_member
--@target_group_name='MasterGroup',
--@target_type='SqlDatabase',
--@server_name='abc.database.windows.net',
--@database_name='master'

-- Add a job to collect perf results
EXEC jobs.sp_add_job
@job_name='ElasticPoolPerfMetrics',
@description='Collect elastic pool performance data',
@schedule_interval_type='Minutes',
@schedule_interval_count=15

-- Add a job step w/ schedule to collect results
EXEC jobs.sp_add_jobstep
@job_name='ElasticPoolPerfMetrics',
@command=N'declare @now datetime
DECLARE @startTime datetime
DECLARE @endTime datetime
DECLARE @poolLagMinutes datetime
DECLARE @poolStartTime datetime
DECLARE @poolEndTime datetime
SELECT @now = getutcdate ()
SELECT @startTime = dateadd(minute, -15, @now)
SELECT @endTime = @now
SELECT @poolStartTime = dateadd(minute, -30, @startTime)
SELECT @poolEndTime = dateadd(minute, -30, @endTime)

SELECT elastic_pool_name , end_time, elastic_pool_dtu_limit, avg_cpu_percent, avg_data_io_percent, avg_log_write_percent, max_worker_percent, max_session_percent,
        avg_storage_percent, elastic_pool_storage_limit_mb FROM sys.elastic_pool_resource_stats
        WHERE end_time > @poolStartTime and end_time <= @poolEndTime;
',
@credential_name='jobcred',
@target_group_name='NonProdGroup1',
@output_type='SqlDatabase',
@output_credential_name='jobcred',
@output_server_name='abc.database.windows.net',
@output_database_name='abcjob',
@output_table_name='Stats_ElasticPools'


------enable job
exec jobs.sp_update_job @job_name = 'ElasticPoolPerfMetrics', @enabled = 1



-- View all jobs
SELECT * FROM jobs.jobs

-- View the steps of the current version of all jobs
SELECT js.* FROM jobs.jobsteps js
JOIN jobs.jobs j 
  ON j.job_id = js.job_id AND j.job_version = js.job_version

-- View the steps of all versions of all jobs
select * from jobs.jobsteps


------run job adhoc
-- Execute the latest version of a job
EXEC jobs.sp_start_job 'ElasticPoolPerfMetrics'

-- Execute the latest version of a job and receive the execution id
declare @je uniqueidentifier
exec jobs.sp_start_job 'ElasticPoolPerfMetrics', @job_execution_id = @je output
select @je

select * from jobs.job_executions where job_execution_id = @je

-- Execute a specific version of a job (e.g. version 1)
exec jobs.sp_start_job 'ElasticPoolPerfMetrics', 1


------monitor job execution
--View top-level execution status for the job named 'ResultsPoolJob'
SELECT * FROM jobs.job_executions 
WHERE job_name = 'ElasticPoolPerfMetrics' and step_id IS NULL
ORDER BY start_time DESC

--View all top-level execution status for all jobs
SELECT * FROM jobs.job_executions WHERE step_id IS NULL
ORDER BY start_time DESC

--View all execution statuses for job named 'ResultsPoolsJob'
SELECT * FROM jobs.job_executions 
WHERE job_name = 'ElasticPoolPerfMetrics' 
ORDER BY start_time DESC

-- View all active executions
SELECT * FROM jobs.job_executions 
WHERE is_active = 1
ORDER BY start_time DESC


------cancel a job
-- View all active executions to determine job execution id
SELECT * FROM jobs.job_executions 
WHERE is_active = 1 AND job_name = 'ElasticPoolPerfMetrics'
ORDER BY start_time DESC
GO

-- Cancel job execution with the specified job execution id
EXEC jobs.sp_stop_job 'CE187C70-8081-4637-A44E-15127E3B0DCA'