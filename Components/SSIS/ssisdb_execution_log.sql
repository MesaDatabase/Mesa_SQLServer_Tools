
select 
  es.event_message_id, 
  es.operation_id, 
  es.package_name,
  es.message_source_name,
  es.threadID,
  es.message_time as StartTime,
  ef.message_time as EndTime 
from catalog.event_messages as es
  join catalog.event_messages as ef on es.operation_id = ef.operation_id and es.package_name = ef.package_name and es.message_source_name = ef.message_source_name and es.threadID = ef.threadID
where es.operation_id = 173628
  and es.event_name = 'OnPreExecute'
  and ef.event_name = 'OnPostExecute'
order by es.message_time desc

select 
  datepart(hour,start_time) as [20170915_Hour], 
  Status, 
  count(1) as ExecutionCount
  --select top 10 *
from catalog.executions
where start_time >= '2017-09-15' 
  AND start_time < '2017-09-16'
  and project_name = 'DB1'
group by datepart(hour,start_time), Status
order by 1

select execution_id, project_name, start_time, end_time, status
from catalog.executions
where start_time >= '2018-04-11' 
  --AND start_time < '2017-09-16'
  and project_name = 'DB2
order by start_time desc