select
  @@SERVERNAME,
  sum(cast(b1.backup_size/1024/1024/1024 as decimal(18,2))) as SizeCompressGB
from msdb.dbo.backupset as b1
  left join msdb.dbo.backupmediaset as b2 on b1.media_set_id = b2.media_set_id
  left join msdb.dbo.backupmediafamily as b3 on b2.media_set_id = b3.media_set_id
where 1=1
  and b1.backup_finish_date >= GETDATE()-1
  and b1.type in ('D','L')
  
exec xp_cmdshell 'wmic volume get DriveLetter,Capacity /FORMAT:csv'

select @@servername, name, recovery_model_desc from sys.databases
where database_id>4 and name not in ('DB2','DB1')
  and recovery_model_desc = 'SIMPLE'