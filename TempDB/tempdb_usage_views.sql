CREATE VIEW all_request_usage
AS 
  SELECT session_id, request_id,
      SUM(internal_objects_alloc_page_count) AS request_internal_objects_alloc_page_count,
      SUM(internal_objects_dealloc_page_count)AS request_internal_objects_dealloc_page_count,
      SUM(user_objects_alloc_page_count)AS request_user_objects_alloc_page_count,
      SUM(user_objects_dealloc_page_count)AS request_user_objects_dealloc_page_count 
	  --select *
  FROM sys.dm_db_task_space_usage 
  GROUP BY session_id, request_id;
GO

ALTER VIEW all_query_usage
AS
  SELECT R1.session_id, R1.request_id, 
      R1.request_internal_objects_alloc_page_count, 
	  R1.request_internal_objects_dealloc_page_count,
      R1.request_user_objects_alloc_page_count, 
	  R1.request_user_objects_dealloc_page_count,
      R2.sql_handle, R2.statement_start_offset, R2.statement_end_offset, R2.plan_handle
  FROM all_request_usage R1
    LEFT JOIN sys.dm_exec_requests R2 ON R1.session_id = R2.session_id and R1.request_id = R2.request_id;
GO

CREATE VIEW all_task_usage
AS 
    SELECT session_id, 
      SUM(internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
      SUM(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count,
      SUM(user_objects_alloc_page_count) AS task_user_objects_alloc_page_count,
      SUM(user_objects_dealloc_page_count) AS task_user_objects_dealloc_page_count 
    FROM sys.dm_db_task_space_usage 
    GROUP BY session_id;
GO

CREATE VIEW all_session_usage 
AS
    SELECT R1.session_id,
        R1.internal_objects_alloc_page_count + R2.task_internal_objects_alloc_page_count AS session_internal_objects_alloc_page_count,
        R1.internal_objects_dealloc_page_count + R2.task_internal_objects_dealloc_page_count AS session_internal_objects_dealloc_page_count,
        R1.user_objects_alloc_page_count + R2.task_user_objects_alloc_page_count AS session_user_objects_alloc_page_count,
        R1.user_objects_dealloc_page_count + R2.task_user_objects_dealloc_page_count AS session_user_objects_dealloc_page_count
    FROM sys.dm_db_session_space_usage AS R1 
      INNER JOIN all_task_usage AS R2 ON R1.session_id = R2.session_id;
GO

--currently running tasks
select * from all_task_usage
where session_id = 65

--completed tasks
select * from all_session_usage
where session_id = 65

SELECT R1.*, R2.text, R3.query_plan 
--select *
FROM all_query_usage AS R1
	--OUTER APPLY sys.dm_exec_sql_text(R1.sql_handle) AS R2
	--OUTER APPLY sys.dm_exec_query_plan(R1.plan_handle) AS R3
where session_id = 65

SELECT R1.*, R2.query_plan 
FROM all_query_usage AS R1
OUTER APPLY sys.dm_exec_query_plan(R1.plan_handle) AS R2;