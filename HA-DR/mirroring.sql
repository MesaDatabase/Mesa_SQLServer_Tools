select * from msdb.sys.database_mirroring
select * from msdb.sys.database_mirroring_endpoints
select * from msdb.sys.dm_db_mirroring_connections

ALTER AUTHORIZATION ON ENDPOINT::Mirroring TO sa
GO


--MONITORING
/*
Monitoring a mirrored database enables you to:
 - Verify that mirroring is functioning - basic status includes: 
	Are the two server instances up
	Are the servers connected
	Is the log being moved from the principal to the mirror
 - Determine whether the mirror database is keeping up with the principal database:
	During high-performance mode, a principal server can develop a backlog of unsent log records that still need to be sent from the principal server to the mirror server
	In any operating mode, the mirror server can develop a backlog of unrestored log records that have been written to the log file but still need to be restored on the mirror database
 - Determine how much data was lost when the principal server instance becomes unavailable during high-performance mode:
	Amount of unsent transaction log
	The time interval in which the lost transactions were committed at the principal
 - Compare current performance with past performance:
	View a history of the mirroring performance
	Look for times of day when the network is slow or the number of commands entering the log is very large
 - Troubleshoot the cause of reduced data flow between mirroring partners
 - Set warning thresholds on key performance metrics

sp_dbmmonitorresults 
 - requires sysadmin or the dbm_monitor role
 - http://technet.microsoft.com/en-us/library/ms366320(v=sql.105).aspx
*/

USE msdb;
EXEC sp_dbmmonitorresults test, 2, 0;


/*
log_generation_rate: Amount of log generated since preceding update of the mirroring status of this database in kilobytes/sec.
 
unsent_log: Size of the unsent log in the send queue on the principal in kilobytes.
 
send_rate: Send rate of log from the principal to the mirror in kilobytes/sec.
 
unrestored_log: Size of the redo queue on the mirror in kilobytes.
 
recovery_rate: Redo rate on the mirror in kilobytes/sec.
 
transaction_delay: Total delay for all transactions in milliseconds.
 
transactions_per_sec: Number of transactions that are occurring per second on the principal server instance. 
 
average_delay: Average delay on the principal server instance for each transaction because of database mirroring. In high-performance mode (that is, when the SAFETY property is set to OFF), this value is generally 0.
 
time_recorded: Time at which the row was recorded by the database mirroring monitor. This is the system clock time of the principal.
 
time_behind: Approximate system-clock time of the principal to which the mirror database is currently caught up. This value is meaningful only on the principal server instance. 
*/ 


