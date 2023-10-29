
DECLARE @CPU decimal, @IO decimal, @NET decimal

	-- Calculate CPU, IO, and Net utilization to see if things are too hectic
	SELECT
	 @CPU = @@CPU_BUSY,
	 @IO = @@IO_BUSY,
	 @NET = CAST(@@PACK_SENT AS DECIMAL) + CAST(@@PACK_RECEIVED AS DECIMAL)
	
	-- SET @NET = @NET + @@PACK_RECEIVED
	
	WAITFOR DELAY '0:0:1'
	
	-- Calculate delta so we can figure out what's going on
	SELECT 
	 @CPU = (@@CPU_BUSY - @CPU) * @@TIMETICKS/10000.0, --Estimate. % in seconds SQL was busy during 1 sec wait. This is most reliable value.
	 @IO = (@@IO_BUSY - @IO) * @@TIMETICKS/10000.0,
	 @NET = (CAST(@@PACK_SENT AS DECIMAL)+ CAST(@@PACK_RECEIVED AS DECIMAL)) - @NET

select @CPU, @IO, @NET