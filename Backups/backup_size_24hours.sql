select @@SERVERNAME,
  case when b1.type = 'D' then 'Full'
		when b1.type = 'L' then 'Log'
		when b1.type = 'I' then 'Diff' end as BackupType,
  sum(cast(b1.backup_size/1024/1024/1024 as decimal(18,2))) as SizeCompressGB
from msdb.dbo.backupset as b1
  left join msdb.dbo.backupmediaset as b2 on b1.media_set_id = b2.media_set_id
  left join msdb.dbo.backupmediafamily as b3 on b2.media_set_id = b3.media_set_id
where 1=1
  and b1.backup_finish_date >= GETDATE()-1
group by   case when b1.type = 'D' then 'Full'
		when b1.type = 'L' then 'Log'
		when b1.type = 'I' then 'Diff' end