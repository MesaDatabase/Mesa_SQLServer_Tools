set nocount on


select 
	1 as RunId,
	getdate() as StartTime,
  case when query_hash = 0x89F7E9E6D2FBD3BE then 'uspDTOVersionClean' 
		when query_hash = 0x9BC4D7AC0D64DBE0 then 'uspDTOVersionSave' end as SprocName,
  qs.execution_count,
  qs.total_elapsed_time
  --select *
into #t1
from sys.dm_exec_query_stats as qs 
       CROSS apply sys.dm_exec_sql_text(qs.sql_handle) as st 
--where st.[text] like '%uspDTOVersionClean%'
--where qs.execution_count >= 384616
where query_hash in (0x89F7E9E6D2FBD3BE,0x9BC4D7AC0D64DBE0)


waitfor delay '00:03:00'


insert into #t1
select 
	2 as RunId,
	getdate() as StartTime,
  case when query_hash = 0x89F7E9E6D2FBD3BE then 'uspDTOVersionClean' 
		when query_hash = 0x9BC4D7AC0D64DBE0 then 'uspDTOVersionSave' end as SprocName,
  qs.execution_count,
  qs.total_elapsed_time
  --select *
--into #t1
from sys.dm_exec_query_stats as qs 
       CROSS apply sys.dm_exec_sql_text(qs.sql_handle) as st 
--where st.[text] like '%uspDTOVersionClean%'
--where qs.execution_count >= 384616
where query_hash in (0x89F7E9E6D2FBD3BE,0x9BC4D7AC0D64DBE0)

select * from #t1

select *
from sys.dm_exec_query_stats as qs 
       CROSS apply sys.dm_exec_sql_text(qs.sql_handle) as st 
where query_hash in (0x89F7E9E6D2FBD3BE,0x9BC4D7AC0D64DBE0)

--drop table #t1