declare @totalmemoryused bigint
declare @bufferpool_allocated bigint
declare @query2008r2_total nvarchar(max)
declare @query2012_total nvarchar(max)
declare @version nvarchar(128)

--select * from sys.dm_os_memory_clerks
--Set @query2008r2_total  = 'select SUM(single_pages_kb+multi_pages_kb+virtual_memory_committed_kb+awe_allocated_kb)/1024 from sys.dm_os_memory_clerks' 
 
set @query2012_total = 'select SUM(pages_kb+virtual_memory_committed_kb+awe_allocated_kb)/1024 from sys.dm_os_memory_clerks'

select @version = cast(SERVERPROPERTY('Productversion') as nvarchar(128))
--select @version
if (@version like '11%' or @version like '12%')
    begin
        create table #tmp (value bigint)
        insert into #tmp Execute (@query2012_total)    
        select @totalmemoryused = value from #tmp
        drop table #tmp
    end
else
    begin
        create table #tmp_1 (value bigint)
        insert into #tmp_1 Execute (@query2008r2_total)    
        select @totalmemoryused = value from #tmp_1
        drop table #tmp_1
    end


select @bufferpool_allocated = cntr_value/1024
--select *
FROM sys.dm_os_performance_counters
WHERE counter_name IN ('Target Server Memory (KB)')

select @@servername, @bufferpool_allocated, @totalmemoryused

if (@bufferpool_allocated > @totalmemoryused)
    begin
        Select @@servername, 'Server has no memory issues' as Comments
    end 
else 
    begin 
        select @@servername, 'Server might have memory issue' as Comments
    end
