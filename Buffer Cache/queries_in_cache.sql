--queries in the procedure cache
/* Use with caution if your server suffers from procedure cache bloat: if you have a large number of application databases on a server running a wide variety of queries, 
it may have a very large procedure cache. Generally, start by running this on a server with a very low amount of load to get a feel for the amount of resources required. 
It's not uncommon for this query to take several minutes on a server with a large number of ad-hoc queries in the procedure cache. 
*/

select total_worker_time/execution_count as AvgCPU, total_worker_time AS TotalCPU
, total_elapsed_time/execution_count as AvgDuration, total_elapsed_time AS TotalDuration  
, total_logical_reads/execution_count as AvgReads, total_logical_reads AS TotalReads
, execution_count   
, substring(st.text, (qs.statement_start_offset/2)+1  
, ((case qs.statement_end_offset  when -1 then datalength(st.text)  
else qs.statement_end_offset  
end - qs.statement_start_offset)/2) + 1) as txt  
, query_plan
from sys.dm_exec_query_stats as qs  
cross apply sys.dm_exec_sql_text(qs.sql_handle) as st  
cross apply sys.dm_exec_query_plan (qs.plan_handle) as qp 
order by 1 desc

--queries in the cache with index scans due to implicit conversions
/* This query can find queries in cache that are doing index scans due to implicit conversions. 
For more details see this post: http://statisticsio.com/Home/tabid/36/articleType/ArticleView/articleId/318/Finding-Index-Scans-due-to-Implicit-Conversions.aspx 
*/

with XMLNAMESPACES 
('http://schemas.microsoft.com/sqlserver/2004/07/showplan' as sql)
select
total_worker_time/execution_count AS AvgCPU
, total_elapsed_time/execution_count AS AvgDuration
, (total_logical_reads+total_physical_reads)/execution_count AS AvgReads
, execution_count
, SUBSTRING(st.TEXT, (qs.statement_start_offset/2)+1 , ((CASE
qs.statement_end_offset WHEN -1 THEN datalength(st.TEXT) ELSE
qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) AS txt
, qs.max_elapsed_time
, db_name(qp.dbid) as database_name
, quotename(object_schema_name(qp.objectid, qp.dbid)) + N'.' + 
quotename(object_name(qp.objectid, qp.dbid)) as obj_name
, qp.query_plan.value( 
N'(/sql:ShowPlanXML/sql:BatchSequence/sql:Batch/sql:Statements/sql:StmtSimple[@StatementType 
= 
"SELECT"]/sql:QueryPlan/sql:RelOp/descendant::*/sql:ScalarOperator[contains(@ScalarString, 
"CONVERT_IMPLICIT")])[1]/@ScalarString', 'nvarchar(4000)' ) as scalar_string
, qp.query_plan
from sys.dm_exec_query_stats as qs
cross apply sys.dm_exec_query_plan(qs.plan_handle) as qp
cross apply sys.dm_exec_sql_text(qs.sql_handle) st
where qp.query_plan.exist( 
N'/sql:ShowPlanXML/sql:BatchSequence/sql:Batch/sql:Statements/sql:StmtSimple[@StatementType 
= 
"SELECT"]/sql:QueryPlan/sql:RelOp/sql:IndexScan/descendant::*/sql:ScalarOperator[contains(@ScalarString, 
"CONVERT_IMPLICIT")]' ) = 1;

