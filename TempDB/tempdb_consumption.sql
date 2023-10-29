SELECT
 
SUM(unallocated_extent_page_count) AS [free pages], (SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB],SUM(version_store_reserved_page_count) AS [version store pages used],
 
(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB],SUM(internal_object_reserved_page_count) AS [internal object pages used],
 
(SUM(internal_object_reserved_page_count)*1.0/128) AS [internal object space in [MB],SUM(user_object_reserved_page_count) AS [user object pages used],
 
(SUM(user_object_reserved_page_count)*1.0/128) AS [user object space in MB]
 
FROM sys.dm_db_file_space_usage;
 
go



SELECT R1.session_id, R1.request_id, R1.Task_request_internal_objects_alloc_page_count, R1.Task_request_internal_objects_dealloc_page_count,
 
R1.Task_request_user_objects_alloc_page_count,R1.Task_request_user_objects_dealloc_page_count,R3.Session_request_internal_objects_alloc_page_count ,
 
R3.Session_request_internal_objects_dealloc_page_count,R3.Session_request_user_objects_alloc_page_count,R3.Session_request_user_objects_dealloc_page_count,
 
R2.sql_handle, RL2.text as SQLText, R2.statement_start_offset, R2.statement_end_offset, R2.plan_handle FROM (SELECT session_id, request_id, 
 
SUM(internal_objects_alloc_page_count) AS Task_request_internal_objects_alloc_page_count, SUM(internal_objects_dealloc_page_count)AS
 
Task_request_internal_objects_dealloc_page_count,SUM(user_objects_alloc_page_count) AS Task_request_user_objects_alloc_page_count,
 
SUM(user_objects_dealloc_page_count)AS Task_request_user_objects_dealloc_page_count FROM sys.dm_db_task_space_usage 
 
GROUP BY session_id, request_id) R1 INNER JOIN (SELECT session_id, SUM(internal_objects_alloc_page_count) AS Session_request_internal_objects_alloc_page_count,
 
SUM(internal_objects_dealloc_page_count)AS Session_request_internal_objects_dealloc_page_count,SUM(user_objects_alloc_page_count) AS Session_request_user_objects_alloc_page_count,
 
SUM(user_objects_dealloc_page_count)AS Session_request_user_objects_dealloc_page_count FROM sys.dm_db_Session_space_usage 
 
GROUP BY session_id) R3 on R1.session_id = R3.session_id 
 
left outer JOIN sys.dm_exec_requests R2 ON R1.session_id = R2.session_id and R1.request_id = R2.request_id
 
OUTER APPLY sys.dm_exec_sql_text(R2.sql_handle) AS RL2
Where
Task_request_internal_objects_alloc_page_count >0 or 
Task_request_internal_objects_dealloc_page_count>0 or
Task_request_user_objects_alloc_page_count >0 or
Task_request_user_objects_dealloc_page_count >0 or
Session_request_internal_objects_alloc_page_count >0 or
Session_request_internal_objects_dealloc_page_count >0 or
Session_request_user_objects_alloc_page_count >0 or
Session_request_user_objects_dealloc_page_count >0 