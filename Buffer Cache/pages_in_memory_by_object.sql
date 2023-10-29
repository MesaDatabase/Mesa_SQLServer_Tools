set nocount on

declare @t1 table (DatabaseId int, DatabaseName varchar(50))
insert into @t1
select dbid, name from master.dbo.sysdatabases 
where name = 'aa'

IF OBJECT_ID('tempdb..#t2') IS NOT NULL DROP TABLE #t2
create table #t2 (DbId int, AllocationUnitId bigint, ObjectName varchar(200), ObjectId bigint)

declare @dbname varchar(50), @dbid int

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
set @dbid = (select DatabaseId from @t1 t1 where DatabaseName = @dbname)

EXEC('USE [' + @dbname + ']; EXEC(''insert into #t2 select db_id(),
	t1.allocation_unit_id,
    object_name(t2.object_id),
    t2.object_id
from sys.allocation_units t1
  join sys.partitions t2 ON (t1.container_id = t2.hobt_id and t1.type in (1,3)) or (t1.container_id = t2.partition_id and t1.type = 2)
  join sys.objects t3 ON t2.object_id = t3.object_id
where t3.type = ''''U'''''');');

delete from @t1 where DatabaseName = @dbname
end 

select 
@@servername as SQLInstance,
  t4.name as dbname,
  t2.ObjectId,
  t2.ObjectName,
  count(1) * 8/1024.0 as BufferSizeMB,
  count(1) as [BufferPageCount] 
from #t2 t2
  join sys.dm_os_buffer_descriptors t3 ON t2.DbId = t3.database_id and t2.AllocationUnitId = t3.allocation_unit_id
  join sys.databases t4 on t3.database_id = t4.database_id
group by t4.name, t2.ObjectId, t2.ObjectName
order by BufferSizeMB desc
  