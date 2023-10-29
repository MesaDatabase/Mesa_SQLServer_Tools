SET NOCOUNT ON

DECLARE @job_id  UNIQUEIDENTIFIER
DECLARE @disable_job CHAR(1)

SET @disable_job = 'Y' -- Fill 'Y' to disable job .. 'N' to enable job

IF OBJECT_ID('tempdb..#sysjobs') IS NOT NULL
   DROP TABLE #sysjobs


SELECT job_id INTO #sysjobs
FROM msdb..sysjobs
WHERE enabled = CASE @disable_job WHEN 'Y' THEN 1 ELSE 0 END
  AND name like 'Log backup%'

WHILE (1 = 1)
BEGIN
   SELECT @job_id = job_id FROM #sysjobs

   IF @@rowcount = 0
      GOTO _EXIT

   
   PRINT 'exec msdb..sp_update_job @job_id = ''' + CAST(@job_id AS VARCHAR(36))+ ''', @enabled = ' 
         + CASE @disable_job WHEN 'Y' THEN '0' ELSE '1' END
   

   PRINT 'GO'   

   DELETE FROM #sysjobs WHERE job_id = @job_id
END

_EXIT:
   DROP TABLE #sysjobs

SET NOCOUNT OFF

 

