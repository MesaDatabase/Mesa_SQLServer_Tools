-- Head of Blocked processes
IF EXISTS
(SELECT * FROM master.dbo.sysprocesses
WHERE spid IN (SELECT blocked FROM master.dbo.sysprocesses))
SELECT
sp.spid, sp.[status], sp.loginame,
sp.hostname, sp.[program_name],
sp.blocked, sp.open_tran,
dbname=db_name(sp.[dbid]), sp.cmd,
sp.waittype, sp.waittime, sp.last_batch, st.[text]
FROM master.dbo.sysprocesses sp
CROSS APPLY sys.dm_exec_sql_text (sp.[sql_handle]) st
WHERE spid IN (SELECT blocked FROM master.dbo.sysprocesses)
AND blocked=0
ELSE
SELECT 'No blocking processes found!' 
