select * from sys.dm_os_sys_info
select * from sys.dm_exec_query_memory_grants
select * from sys.dm_exec_requests
select * from sys.dm_exec_query_plan
select * from sys.dm_exec_sql_text

--check memory configs
sp_configure 'min server memory'
go
sp_configure 'max server memory'
go
sp_configure 'min memory per query'
go
sp_configure 'query wait'
go

--see cpu, scheduler memory and buffer pool information
select 
  physical_memory_kb/1024 AS physical_memory_mb, 
  virtual_memory_kb/1024 AS virtual_memory_in_mb, 
  committed_kb/1024 AS bpool_committed_mb,  --max server memory/physical RAM in the buffer pool
  committed_target_kb/1024 AS bpool_commit_targt_mb, --needed physical RAM in buffer pool
  visible_target_kb/1024 AS bpool_visible_mb  --total size of all buffers in the buffer pool that can be directly addressed
--select * 
FROM sys.dm_os_sys_info


--Internal memory distribution
dbcc memorystatus

--To find out how much memory has been allocated through AWE mechanism
SELECT Sum(awe_allocated_kb)/1024 as 'AWE allocated MB'
FROM sys.dm_os_memory_clerks

--amount of mem allocated though multipage allocator interface
select sum(multi_pages_kb) /1024 as 'MultiPage allocated, MB'
from sys.dm_os_memory_clerks
--broken down in Detail
select type, sum(multi_pages_kb)/1024 as 'MultiPage allocated, MB'
from sys.dm_os_memory_clerks
where multi_pages_kb != 0
group by type

-- amount of memory consumed by components outside the Buffer pool 
-- note that we exclude single_pages_kb as they come from BPool
select
    sum(multi_pages_kb 
        + virtual_memory_committed_kb
        + shared_memory_committed_kb) as [Overall used w/o BPool, Kb]
from sys.dm_os_memory_clerks 
where type <> 'MEMORYCLERK_SQLBUFFERPOOL'

-- amount of memory consumed by BPool
-- note that currenlty only BPool uses AWE
select
    sum(multi_pages_kb 
        + virtual_memory_committed_kb
        + shared_memory_committed_kb
        + awe_allocated_kb) as [Used by BPool with AWE, Kb]
        --select *
from sys.dm_os_memory_clerks 
where type = 'MEMORYCLERK_SQLBUFFERPOOL'


--top 10 consumers of memory from BPool
select top 10 type, sum(pages_kb)/1024 as [SPA Mem, MB]
from sys.dm_os_memory_clerks
group by type
order by sum(pages_kb) desc

--Info about clock hand movements – Increasing rounds count indicate memory pressure
select *
from
  sys.dm_os_memory_cache_clock_hands
where
  rounds_count > 0
  and removed_all_rounds_count > 0

--Detailed
  select
  distinct cc.cache_address,
  cc.name,
  cc.type,
  cc.single_pages_kb + cc.multi_pages_kb as total_kb,
  cc.single_pages_in_use_kb + cc.multi_pages_in_use_kb as total_in_use_kb,
  cc.entries_count,
  cc.entries_in_use_count,
  ch.removed_all_rounds_count,
  ch.removed_last_round_count
from
  sys.dm_os_memory_cache_counters cc
  join sys.dm_os_memory_cache_clock_hands ch on (cc.cache_address = ch.cache_address)
order by total_kb desc

