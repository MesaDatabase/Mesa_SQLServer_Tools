declare @t1 table (DbName varchar(255), RestoreHistoryId int)

insert into @t1
select s1.destination_database_name, max(restore_history_id)
from msdb.dbo.restorehistory as s1
  join sys.databases as s2 on s1.destination_database_name = s2.name
where database_id > 4
  and name not in ('a','b')
group by s1.destination_database_name

select 
  s1.destination_database_name, 
  s1.restore_date, 
  s2.backup_start_date, 
  s2.backup_finish_date, 
  s2.database_name as source_database_name, 
  s3.physical_device_name as backup_file_used_for_restore
--select *
from msdb.dbo.restorehistory as s1
  join msdb.dbo.backupset as s2 on s1.backup_set_id = s2.backup_set_id
  join msdb.dbo.backupmediafamily as s3 on s2.media_set_id = s3.media_set_id 
  join @t1 as t1 on s1.restore_history_id = t1.RestoreHistoryId and s1.destination_database_name = t1.DbName
where 1=1
  --and backup_start_date < '2015-07-27'
order by destination_database_name
 

