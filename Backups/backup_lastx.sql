select distinct @@servername as Server,
  b1.database_name, 
  b1.backup_start_date,
  b1.backup_finish_date,
  DATEDIFF(MINUTE,b1.backup_start_date,b1.backup_finish_date) as Duration,
  case when b1.type = 'D' then 'Full'
		when b1.type = 'L' then 'Log'
		when b1.type = 'I' then 'Diff' end as BackupType,
  cast(b1.compressed_backup_size/media_family_count/1024/1024/1024 as decimal(18,2)) as SizeCompressGB,
  b2.software_name,
  case when b3.physical_device_name like 'VNBU%' then left(b3.physical_device_name,4) else b3.physical_device_name end as PhysicalDeviceName,
  cast(b1.compressed_backup_size/media_family_count/1024/1024 as decimal(18,2))/(case when (DATEDIFF(second,b1.backup_start_date,b1.backup_finish_date))=0 then 1 else DATEDIFF(second,b1.backup_start_date,b1.backup_finish_date) end) as MBperSec
from msdb.dbo.backupset as b1
  left join msdb.dbo.backupmediaset as b2 on b1.media_set_id = b2.media_set_id
  left join msdb.dbo.backupmediafamily as b3 on b2.media_set_id = b3.media_set_id
where 1=1
  and b1.backup_finish_date >= GETDATE()-1
  and b1.type = 'D'
--  and b1.database_name in ('OrderDB')
order by b1.database_name, b1.backup_finish_date desc