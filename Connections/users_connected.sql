--users connected
SELECT login_name, original_login_name, COUNT(session_id) AS session_count 
FROM sys.dm_exec_sessions 
GROUP BY login_name, original_login_name
order by count(session_id)
