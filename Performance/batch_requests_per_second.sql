declare @value1 bigint
declare @value2 bigint

set @value1 = (select cntr_value from sys.dm_os_performance_counters (nolock)
			   where object_name = 'SQLServer:SQL Statistics'
				 and counter_name = 'Batch Requests/sec')
				 
waitfor delay '00:00:05'

set @value2 = (select cntr_value from sys.dm_os_performance_counters (nolock)
			   where object_name = 'SQLServer:SQL Statistics'
				 and counter_name = 'Batch Requests/sec')

select cast((@value2-@value1) as decimal(17,2))/5



