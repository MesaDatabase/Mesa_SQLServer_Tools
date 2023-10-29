select qs.execution_count,
    substring(qt.text,qs.statement_start_offset/2 +1, 
                 (case when qs.statement_end_offset = -1 
                       then len(convert(nvarchar(max), qt.text)) * 2 
                       else qs.statement_end_offset end -
                            qs.statement_start_offset
                 )/2
             ) as query_text, 
     qt.dbid, dbname= DB_NAME (qt.dbid), qt.objectid, 
     qs.total_rows, qs.last_rows, qs.min_rows, qs.max_rows
from sys.dm_exec_query_stats as qs 
cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt 
where qt.text like '%SELECT%' 
order by qs.execution_count desc