select 
  b1.type,
  datepart(year,b1.backup_start_date),
  datepart(month,b1.backup_start_date),
  datepart(day,b1.backup_start_date),
  sum(cast(b1.compressed_backup_size/media_family_count/1024/1024/1024 as decimal(18,2))) as SizeCompressGB
  from msdb.dbo.backupset as b1
  left join msdb.dbo.backupmediaset as b2 on b1.media_set_id = b2.media_set_id
  left join msdb.dbo.backupmediafamily as b3 on b2.media_set_id = b3.media_set_id
where 1=1
  and b1.backup_finish_date >= GETDATE()-30
  and b1.type = 'D'
group by b1.type,  datepart(year,b1.backup_start_date),
  datepart(month,b1.backup_start_date),
  datepart(day,b1.backup_start_date)
order by 2,3,4,1