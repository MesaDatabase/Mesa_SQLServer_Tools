select
          [object]
            = quoteName(object_schema_name(tblSIP.object_id))
                + '.'
                + quoteName(object_name(tblSIP.object_id))
 
        , tblSO.[type_desc]
 
        , [totalPages] 
            = sum(tblSIAU.total_pages)
 
        , [totalKB] 
            = sum(tblSIAU.total_pages * 8)
 
from   tempdb.sys.system_internals_allocation_units tblSIAU
 
JOIN   tempdb.sys.system_internals_partitions tblSIP
 
        ON tblSIAU.container_id = tblSIP.partition_id
 
inner join sys.objects tblSO
    on tblSIP.object_id = tblSO.object_id
 
where  tblSO.[type] not in
        (
            'S'
        )
 
group by
          tblSIP.[object_id]
        , tblSO.[type_desc]
 
order by
        sum(tblSIAU.total_pages) desc