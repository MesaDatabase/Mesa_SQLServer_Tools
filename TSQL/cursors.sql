DECLARE @dbid int

DECLARE dbs CURSOR FOR  
  select dbid from msdb.dbo.ED_LogShip_Status

OPEN dbs  
FETCH NEXT FROM dbs INTO @dbid
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
  < do stuff >
  FETCH NEXT FROM dbs INTO @dbid
END  
  
CLOSE dbs  

DEALLOCATE dbs