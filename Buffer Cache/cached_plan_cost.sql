select 
  p.plan_handle,
  p.usecounts,
  p.size_in_bytes,
  p.objtype,
  mc.current_cost,
  mc.pages_allocated_count
--select top 10 *
from sys.dm_exec_cached_plans p (nolock)
  join sys.dm_os_memory_objects mo (nolock) on p.memory_object_address = mo.memory_object_address or p.memory_object_address = mo.parent_address
  join sys.dm_os_memory_cache_entries mc (nolock) on p.memory_object_address = mc.memory_object_address
where cacheobjtype = 'Compiled Plan'