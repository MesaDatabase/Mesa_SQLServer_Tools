-------------------START TRACE IN PROFILER-----------------------
--Create, start and stop trace
--Save as trace file
--Save as sql script

-------------------CREATE STORED PROC----------------------------
--replace events and filters with those from sql file
USE msdb
GO

CREATE PROCEDURE trace_start
	@file_name nvarchar(155), -- NOTE: no file extension
	@trace_id int output
AS

DECLARE @rc int
DECLARE @TraceID int
DECLARE @maxfilesize bigint
SET @maxfilesize = 5 

EXEC @rc = sp_trace_create @TraceID output, 0, @file_name, @maxfilesize, NULL 

IF (@rc != 0) 
  RAISERROR ('Error with the sp_trace_create', 16,1)
ELSE
BEGIN
	-- set the events
	DECLARE @on bit
	SET @on = 1
	EXEC sp_trace_SETevent @TraceID, 20, 8, @on
	EXEC sp_trace_SETevent @TraceID, 20, 1, @on
	EXEC sp_trace_SETevent @TraceID, 20, 9, @on
	EXEC sp_trace_SETevent @TraceID, 20, 10, @on
	EXEC sp_trace_SETevent @TraceID, 20, 14, @on
	EXEC sp_trace_SETevent @TraceID, 20, 11, @on
	EXEC sp_trace_SETevent @TraceID, 20, 35, @on
	EXEC sp_trace_SETevent @TraceID, 20, 12, @on

	-- set the Filters
	DECLARE @intfilter int
	DECLARE @bigintfilter bigint

	-- set the trace status to start
	EXEC sp_trace_SETstatus @TraceID, 1
	SET @trace_id = @traceID	-- Return the ID of the trace
END


-------------------CREATE TRACE TABLE and TABLE FOR FILE LOCATIONS----------------------------
select * into msdb.dbo.myTrace
from ::fn_trace_gettable('C:\Users\user\Documents\login_failed.trc', default)
  
select * from
--delete from
--drop table
msdb.dbo.myTrace

create table msdb.dbo.trace_files(
  tid int primary key identity(1,1) NOT NULL,
  output_path_file varchar(100) NOT NULL,
  output_path_file_ext AS (output_path_file + '.trc'))
     
insert into msdb.dbo.trace_files (output_path_file)
select 'C:\Users\user\Documents\login_failed'  --no ext

select * from msdb.dbo.trace_files


-------------------CREATE JOB TO START TRACE----------------------------
DECLARE @path_file nvarchar(200)
SELECT 
  @path_file=output_path_file 
  FROM msdb.dbo.trace_files WHERE tid = 1
EXEC msdb.dbo.trace_start @path_file, null


-------------------CREATE JOB TO STOP TRACE, LOAD DATA & CLEANUP----------------------------
--Step 1
DECLARE @trace_ID int, @path_file nvarchar(200)
SELECT @path_file=output_path_file FROM msdb.dbo.trace_files WHERE tid = 1

SELECT @trace_ID = traceid FROM ::fn_trace_getinfo(0)
WHERE property = 2 AND value = @path_file

EXEC sp_trace_setstatus @trace_ID, 0	--<< stop
EXEC sp_trace_setstatus @trace_ID, 2	--<< close

--Step 2
DECLARE @path_file_ext nvarchar(200)
SELECT @path_file_ext=output_path_file_ext FROM msdb.dbo.trace_files WHERE tid = 1

INSERT INTO msdb.dbo.myTrace
SELECT *
FROM ::fn_trace_gettable(@path_file_ext, default)

--Step 3
DECLARE @path_file_ext nvarchar(200), @cmd sysname
SELECT @path_file_ext=output_path_file_ext FROM msdb.dbo.trace_files WHERE tid = 1

SET @cmd = 'del ' + @path_file_ext
EXEC master.dbo.xp_cmdshell @cmd


-------------------VIEW TRACE and DATA----------------------------
--view if trace is running
SELECT * FROM ::fn_trace_getinfo(default)

--view data in trace table
select * from  msdb.dbo.myTrace t1
  join sys.trace_events t2 on t1.EventClass = t2.trace_event_id

--select * from sys.trace_categories
--select * from sys.trace_columns
--select * from sys.trace_event_bindings
--select * from sys.trace_events
--select * from sys.trace_subclass_values

