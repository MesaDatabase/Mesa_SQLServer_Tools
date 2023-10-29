select *
from sys.allocation_units t1
  join sys.partitions t2 ON (t1.container_id = t2.hobt_id and t1.type in (1,3)) or (t1.container_id = t2.partition_id and t1.type = 2)
  join sys.objects t3 ON t2.object_id = t3.object_id
where t3.type = 'U'