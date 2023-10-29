--what queries are using all the cpu?
DECLARE @Count INT
SET @Count = 25

;WITH DB_CPU_Stats
AS
(
  SELECT
    ROW_NUMBER() over(order by sum(total_worker_time) desc) as rn,
    DatabaseID,
    plan_handle,
    DB_Name(DatabaseID) AS [DatabaseName],
    SUM(total_worker_time) AS [CPU_Time_Ms]
  FROM sys.dm_exec_query_stats AS qs
  CROSS APPLY
    (
      SELECT
        CONVERT(int, value) AS [DatabaseID]
      FROM sys.dm_exec_plan_attributes(qs.plan_handle)
      WHERE attribute = N'dbid'
    ) AS F_DB
  GROUP BY DatabaseID, plan_handle
), PlanHandleQuery as (
SELECT
  ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [row_num],
    DatabaseName,
    t2.query_plan,
    OBJECT_NAME(objectid) as ObjectName,
    [CPU_Time_Ms],
    CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPUPercent]
FROM DB_CPU_Stats
cross apply sys.dm_exec_query_plan(plan_handle) t2
WHERE (DatabaseID > 4) AND (DatabaseID <> 32767)
AND rn <= @Count
)
SELECT DatabaseName, query_plan, ObjectName, CPU_Time_Ms, CPUPercent
FROM PlanHandleQuery
WHERE row_num <= @Count
ORDER BY row_num

--You can now click on the link in the query_plan column, and the cached execution plan will open. In this execution plan you can right click and choose “Edit Query Text”: