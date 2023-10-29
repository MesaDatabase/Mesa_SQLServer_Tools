--sample_ms: num of ms since computer was started
--num_of_reads: num of reads issued on the file
--num_of_bytes_read: total num of bytes read on the file
--io_stall_read_ms: total time in ms that users waited for writes to be completed on the file
--num_of_writes: num of writes made on the file
--num_of_bytes_written: total number of bytes written to the file
--io_stall_write_ms: total time in ms that users waited for writes to be completed on the file
--io_stall: total time in ms that users waited for I/O to be completed on the file
--size_on_disk_bytes: num of bytes used on the disk for this file

--reads averaging longer than 50ms
select 
  @@servername as server,
  getdate() as QueryDate,
  (select sqlserver_start_time from sys.dm_os_sys_info) as ServerStartTime,
  db_name(database_id),
  cast((io_stall_read_ms/(1.0+num_of_reads)) as int) as avg_read_ms, 
  cast((io_stall_write_ms/(1.0+num_of_writes)) as int) as avg_write_ms, 
  *
from sys.dm_io_virtual_file_stats(NULL, NULL)
where (io_stall_read_ms/(1.0+num_of_reads)) > 50


--writes averaging longer than 20ms
select
  @@servername as server,
  getdate() as QueryDate,
  (select sqlserver_start_time from sys.dm_os_sys_info) as ServerStartTime,
  db_name(database_id),
  cast((io_stall_read_ms/(1.0+num_of_reads)) as int) as avg_read_ms, 
  cast((io_stall_write_ms/(1.0+num_of_writes)) as int) as avg_write_ms, 
  *
from sys.dm_io_virtual_file_stats(NULL, NULL)
where (io_stall_write_ms/(1.0+num_of_writes)) > 20

--look at all file stats
select 
  @@servername as server,
  getdate() as QueryDate,
  (select sqlserver_start_time from sys.dm_os_sys_info) as ServerStartTime,
  db_name(database_id),
  cast((io_stall_read_ms/(1.0+num_of_reads)) as int) as avg_read_ms, 
  cast((io_stall_write_ms/(1.0+num_of_writes)) as int) as avg_write_ms, 
  *
from sys.dm_io_virtual_file_stats(NULL, NULL)

--look at all file stats for specified db
--select * from sys.database_files
select 
  @@servername as server,
  getdate() as QueryDate,
  (select sqlserver_start_time from sys.dm_os_sys_info) as ServerStartTime,
  db_name(database_id),
  cast((io_stall_read_ms/(1.0+num_of_reads)) as int) as avg_read_ms, 
  cast((io_stall_write_ms/(1.0+num_of_writes)) as int) as avg_write_ms, 
  *
from sys.dm_io_virtual_file_stats(2, NULL)


