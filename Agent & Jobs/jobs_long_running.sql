SELECT 
	j.job_id AS 'JobId',
	name AS 'JobName',
	start_execution_date AS 'StartTime',
	stop_execution_date AS 'StopTime',
	avgruntimeonsucceed,
	DATEDIFF(s,start_execution_date,GETDATE()) AS 'CurrentRunTime',
	CASE WHEN stop_execution_date IS NULL THEN 
			DATEDIFF(ss,start_execution_date,stop_execution_date) ELSE 0 END 'ActualRunTime',
	CASE 
		WHEN stop_execution_date IS NULL THEN 'JobRunning'
		WHEN DATEDIFF(ss,start_execution_date,stop_execution_date) 
			> (AvgRunTimeOnSucceed + AvgRunTimeOnSucceed * .05) THEN 'LongRunning-History'
		ELSE 'NormalRunning-History'
	END 'JobRun',
	CASE 
		WHEN stop_execution_date IS NULL THEN
			CASE WHEN DATEDIFF(ss,start_execution_date,GETDATE())
						> (AvgRunTimeOnSucceed + AvgRunTimeOnSucceed * .05) THEN 'LongRunning-NOW'
			ELSE 'NormalRunning-NOW'
		END
		ELSE 'JobAlreadyDone'
	END AS 'JobRunning'
 FROM msdb.dbo.sysjobactivity ja
	INNER JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
INNER JOIN (
	SELECT job_id,
	AVG
	((run_duration/10000 * 3600) + ((run_duration%10000)/100*60) + (run_duration%10000)%100)
	+
	STDEV
	((run_duration/10000 * 3600) + ((run_duration%10000)/100*60) + (run_duration%10000)%100) AS 'AvgRuntimeOnSucceed'
	 FROM msdb.dbo.sysjobhistory
	WHERE step_id = 0 AND run_status = 1
	GROUP BY job_id) art 
	ON j.job_id = art.job_id
WHERE 
(stop_execution_date IS NULL) OR 
	(DATEDIFF(ss,start_execution_date,stop_execution_date) > 60
	AND 
	CAST(LEFT(start_execution_date,11) AS DATETIME) = CAST(LEFT(GETDATE(),11) AS DATETIME))
ORDER BY start_execution_date DESC
