select
  @@servername as ServerName,
  LEFT(s1.filename,1) as Drive,
  case when s1.filename like '%.mdf%' then 'DATA'
	   when s1.filename like '%.ndf%' then 'DATA'
	   when s1.filename like '%.ldf%' then 'LOG' 
	   else s1.filename end as FileType,
  cast(cast(sum(io_stall_read_ms)  as decimal(18,2))/(1+cast(sum(num_of_reads)  as decimal(18,2))) as numeric(8,2)) as avg_read_ms, 
  cast((cast(sum(io_stall_write_ms) as decimal(18,2))/(1+cast(sum(num_of_writes) as decimal(18,2)))) as numeric(8,2)) as avg_write_ms
  --select *
from sys.dm_io_virtual_file_stats(NULL, NULL) as f1
  join dbo.sysaltfiles as s1 on f1.database_id = s1.dbid and f1.file_id = s1.fileid
group by
  LEFT(s1.filename,1),
  case when s1.filename like '%.mdf%' then 'DATA'
	   when s1.filename like '%.ndf%' then 'DATA'
	   when s1.filename like '%.ldf%' then 'LOG' 
	   else s1.filename end
order by 1,2,3   