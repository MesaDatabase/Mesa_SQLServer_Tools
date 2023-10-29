

DECLARE @t1 TABLE (JobId uniqueidentifier, MaxSessionId int)
INSERT INTO @t1
SELECT job_id, MAX(session_id) 
FROM msdb.dbo.sysjobactivity
WHERE run_requested_date IS NOT NULL
GROUP BY job_id

SELECT
    j.job_id, 
    j.name, 
    a.run_requested_date, 
	a.stop_execution_date,
    DATEDIFF(MINUTE, a.run_requested_date, a.stop_execution_date) as DurationMins,
	CASE WHEN a.stop_execution_date IS NULL THEN 'Running' 
		WHEN h.run_status = 0 THEN 'Failed'
		WHEN h.run_status = 1 THEN 'Completed Successfully'
		WHEN h.run_status = 2 THEN 'Retry'
		WHEN h.run_status = 3 THEN 'Cancelled'
		WHEN h.run_status = 4 THEN 'Failed'
		END AS JobStatus,
	h.message
FROM msdb.dbo.sysjobs_view AS j
	LEFT JOIN @t1 AS t1 ON j.job_id = t1.JobId
	LEFT JOIN msdb.dbo.sysjobactivity AS a ON j.job_id = a.job_id AND t1.MaxSessionId = a.session_id
	LEFT JOIN sysjobhistory as h on a.job_history_id = h.instance_id
WHERE j.name = 'name'
ORDER by j.name
