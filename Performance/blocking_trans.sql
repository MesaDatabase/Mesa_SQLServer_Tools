-- Head of Blocked processes
BEGIN
IF EXISTS (SELECT * FROM master.sys.sysprocesses WHERE spid IN (SELECT blocked FROM master.dbo.sysprocesses))
	SELECT
		sp.spid, sp.[status], sp.loginame,
		sp.hostname, sp.[program_name],
		sp.blocked, sp.open_tran,
		dbname=db_name(sp.[dbid]), sp.cmd,
		sp.waittype, sp.waittime, sp.last_batch, st.[text]
	FROM master.sys.sysprocesses sp
		CROSS APPLY sys.dm_exec_sql_text (sp.[sql_handle]) st
	WHERE spid IN (SELECT blocked FROM master.sys.sysprocesses)
		AND blocked=0
ELSE
SELECT 'No blocking processes found!' 
END

exec sp_who2

SELECT * FROM master.sys.sysprocesses sp
		CROSS APPLY sys.dm_exec_sql_text (sp.[sql_handle]) st

SELECT t.[text], p.spid, p.hostname, p.loginame, p.program_name, dt.*
FROM sys.sysprocesses p
cross apply sys.dm_exec_sql_text(sql_handle) t
JOIN sys.dm_tran_session_transactions st ON p.spid = st.session_id
JOIN sys.dm_tran_database_transactions dt ON st.transaction_id = dt.transaction_id

select 
  db_name(resource_database_id) as DbName,
*
--select *
from sys.dm_tran_locks;