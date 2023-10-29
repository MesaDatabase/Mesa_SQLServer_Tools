----------------------------------------------------------------------------------------------------------
----------------------------INDEXES-----------------------------
----------------------------------------------------------------------------------------------------------
set nocount on

--SCRIPT #34: Index Duplicates
declare @t0 table (DbName varchar(255))
insert into @t0
select name from sys.databases
where database_id > 4
  and state_desc = 'ONLINE'

create table #t1  (ObjectId bigint, IndexId int, Name varchar(255), Columns varchar(255), InclCols varchar(255))
create table #t2 (DbName varchar(255), TableName varchar(255), IndexName varchar(255), ExactDupName varchar(255))

declare @sql varchar(4000)
declare @db varchar(255)

while exists (select 1 from @t0)
begin
  set @db = (select top 1 DbName from @t0)
  set @sql = 'use ' + @db + ';
	insert into #t1
	select object_id, index_id, name,
	(select case keyno when 0 then NULL else colid end as [data()]
	from sys.sysindexkeys as k
	where k.id = i.object_id
	and k.indid = i.index_id
	order by keyno, colid
	for xml path('''')),
	(select case keyno when 0 then colid else NULL end as [data()]
	from sys.sysindexkeys as k
	where k.id = i.object_id
	and k.indid = i.index_id
	order by colid
	for xml path('''')) as inc
	from sys.indexes as i'
 
  exec(@sql)

  set @sql = 'use ' + @db + ';
  	insert into #t2
	select db_name(),
	object_schema_name(t1.ObjectId) + ''.'' + object_name(t1.ObjectId),
	t1.name,
	t2.name
	from #t1 as t1
	join #t1 as t2
	on t1.ObjectId = t2.ObjectId
	and t1.IndexId < t2.IndexId
	and t1.Columns = t2.Columns
	and t1.InclCols = t2.InclCols;'

  exec(@sql)
  
  delete from @t0 where DbName = @db
  truncate table #t1
end

select 34 as ScriptNum, @@servername as SQLInstance, * from #t2

drop table #t1
drop table #t2


--SCRIPT #35: Overlapping Indexes
declare @t1 table (DbName varchar(255))
insert into @t1
select name from sys.databases
where database_id > 4
  and state_desc = 'ONLINE'

create table #t3  (ObjectId bigint, IndexId int, Name varchar(255), Columns varchar(255))
create table #t4 (DbName varchar(255), TableName varchar(255), IndexName varchar(255), PartialDupName varchar(255))

declare @sql1 varchar(4000)
declare @db1 varchar(255)

while exists (select 1 from @t1)
begin
  set @db1 = (select top 1 DbName from @t1)
  set @sql1 = 'use ' + @db1 + ';
	insert into #t3
	select object_id, index_id, name,
	(select case keyno when 0 then NULL else colid end as [data()]
	from sys.sysindexkeys as k
	where k.id = i.object_id
	and k.indid = i.index_id
	order by keyno, colid
	for xml path(''''))
	from sys.indexes as i'
 
  exec(@sql1)

  set @sql1 = 'use ' + @db1 + ';
  	insert into #t4
	select db_name(),
	object_schema_name(t3a.ObjectId) + ''.'' + object_name(t3a.ObjectId),
	t3a.name,
	t3b.name
	from #t3 as t3a
	join #t3 as t3b
	on t3a.ObjectId = t3b.ObjectId
	and t3a.IndexId < t3b.IndexId
	and (t3a.Columns like t3b.Columns + ''%'' 
	or t3b.Columns like t3a.Columns + ''%'')'

  exec(@sql1)
  
  delete from @t1 where DbName = @db1
  truncate table #t3
end

select 35 as ScriptNum, @@servername as SQLInstance, * from #t4

drop table #t3
drop table #t4


--SCRIPT #36: Index width
declare @t2 table (DbName varchar(255))
insert into @t2
select name from sys.databases
where database_id > 4
  and state_desc = 'ONLINE'

create table #t5  (DbName varchar(255), SchemaName varchar(255), TableName varchar(255), IndexName varchar(255), IndexType varchar(255), ColumnName varchar(255), IsIncludedColumn bit, MaxLength bigint)

declare @sql2 varchar(4000)
declare @db2 varchar(255)

while exists (select 1 from @t2)
begin
  set @db2 = (select top 1 DbName from @t2)
  set @sql2 = 'use ' + @db2 + ';
	insert into #t5
	select db_name(),
	  	SCHEMA_NAME(o.schema_id),
		o.name,
		i.name,
		i.type,
		c.name,
		ic.is_included_column,
		c.max_length
		FROM sys.objects o 
		join sys.indexes i ON i.object_id = o.object_id
		join sys.index_columns ic on i.object_id = ic.object_id and i.index_id = ic.index_id
		join sys.columns c on o.object_id = c.object_id and ic.column_id = c.column_id
		where o.type = ''U''
		  and is_ms_shipped = 0'
 
  exec(@sql2)
  
  delete from @t2 where DbName = @db2
end

select 36 as ScriptNum, @@servername as SQLInstance, DbName, SchemaName, TableName, IndexName, IndexType, SUM(MaxLength)
from #t5
group by DbName, SchemaName, TableName, IndexName, IndexType
order by DbName, SchemaName, TableName, IndexName, IndexType

drop table #t5


--SCRIPT #37: Missing indexes
declare @t3 table (DbName varchar(255))
insert into @t3
select name from sys.databases
where database_id > 4
  and state_desc = 'ONLINE'

create table #t6  (DbName varchar(255), SchemaName varchar(255), TableName varchar(255), Impact numeric(18,2), EqualityColumns varchar(2000), InequalityColumns varchar(2000), IncludedColumns varchar(2000))

declare @sql3 varchar(4000)
declare @db3 varchar(255)

while exists (select 1 from @t3)
begin
  set @db3 = (select top 1 DbName from @t3)
  set @sql3 = 'use ' + @db3 + ';
	insert into #t6
	select db_name(),
	  SCHEMA_NAME(o.schema_id),
	  o.name,
	  (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans),
	  mid.equality_columns,
	  mid.inequality_columns,
	  mid.included_columns 
	from sys.dm_db_missing_index_group_stats as migs 
	  join sys.dm_db_missing_index_groups as mig on migs.group_handle = mig.index_group_handle 
	  join sys.dm_db_missing_index_details as mid on mig.index_handle = mid.index_handle and mid.database_id = db_id() 
	  join sys.objects as o on mid.object_id = o.object_id
	where (migs.group_handle in ( 
			select top 500 group_handle 
			from sys.dm_db_missing_index_group_stats (nolock) 
			order by (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) desc))  
	  and OBJECTPROPERTY(o.object_id, ''isusertable'')=1 
	order by 2 desc , 3 desc'
 
  exec(@sql3)
  
  delete from @t3 where DbName = @db3
end

select 37 as ScriptNum, @@servername as SQLInstance, * from #t6

drop table #t6


--SCRIPT #38: Heap tables
declare @t4 table (DbName varchar(255))
insert into @t4
select name from sys.databases
where database_id > 4
  and state_desc = 'ONLINE'

create table #t7  (DbName varchar(255), SchemaName varchar(255), TableName varchar(255), RowCnt bigint, UserSeeks bigint, UserScans bigint, UserLookups bigint, UserUpdates bigint, LastUserSeek datetime, LastUserScan datetime, LastUserLookup datetime, LastUserUpdate datetime)

declare @sql4 varchar(4000)
declare @db4 varchar(255)

while exists (select 1 from @t4)
begin
  set @db4 = (select top 1 DbName from @t4)
  set @sql4 = 'use ' + @db4 + ';
	insert into #t7
	select db_name(),
	SCHEMA_NAME(o.schema_id) 
	,object_name(i.object_id) 
	,p.rows
	,user_seeks 
	,user_scans 
	,user_lookups 
	,user_updates 
	,last_user_seek 
	,last_user_scan 
	,last_user_lookup 
	,last_user_update
	FROM sys.indexes i      
	INNER JOIN sys.objects o ON i.object_id = o.object_id
	INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id 
	LEFT OUTER JOIN sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id 
	WHERE i.type_desc = ''HEAP''
	 and last_user_scan is not null
	 and is_ms_shipped = 0'
 
  exec(@sql4)
  
  delete from @t4 where DbName = @db4
end

select 38 as ScriptNum, @@servername as SQLInstance, * from #t7

drop table #t7


--SCRIPT #39: Tables with no indexes
declare @t5 table (DbName varchar(255))
insert into @t5
select name from sys.databases
where database_id > 4
  and state_desc = 'ONLINE'

create table #t8  (DbName varchar(255), SchemaName varchar(255), TableName varchar(255), IndexName varchar(255), IndexType varchar(255))

declare @sql5 varchar(4000)
declare @db5 varchar(255)

while exists (select 1 from @t5)
begin
  set @db5 = (select top 1 DbName from @t5)
  set @sql5 = 'use ' + @db5 + ';
	insert into #t8
	select db_name(),
	SCHEMA_NAME(o.schema_id),
	o.name,
	i.name,
	i.type
	FROM sys.objects o 
	left join sys.indexes i ON i.object_id = o.object_id
	where o.type = ''U''
	  and i.name is null'
 
  exec(@sql5)
  
  delete from @t5 where DbName = @db5
end

select 39 as ScriptNum, @@servername as SQLInstance, * from #t8

drop table #t8


--SCRIPT #40: Unclosed cursors
declare @t6 table (DbName varchar(255))
insert into @t6
select name from sys.databases
where database_id > 4
  and state_desc = 'ONLINE'

create table #t9  (DbName varchar(255), SchemaName varchar(255), ObjectName varchar(255), Type varchar(255))

declare @sql6 varchar(4000)
declare @db6 varchar(255)

while exists (select 1 from @t6)
begin
  set @db6 = (select top 1 DbName from @t6)
  set @sql6 = 'use ' + @db6 + ';
	insert into #t9
	select db_name(),
	SCHEMA_NAME(o.schema_id),
	o.name,
	o.type_desc
    from sys.sql_modules m 
      join sys.objects  o ON m.object_id=o.object_id
    where m.definition Like ''%cursor%''
      and m.definition like ''%open%''
      and m.definition not like ''%close%'' 
      and m.definition not like ''%deallocate%'''
 
  exec(@sql6)
  
  delete from @t6 where DbName = @db6
end

select distinct 40 as ScriptNum, @@servername as SQLInstance, 
DbName, SchemaName, ObjectName, Type
from #t9

drop table #t9


--SCRIPT #41: Logins with blank passwords
SELECT 41 as ScriptNum, @@servername as SQLInstance, name FROM sys.sql_logins 
WHERE PWDCOMPARE('', password_hash) = 1 ;


--SCRIPT #42: Logins with password same as username
SELECT 42 as ScriptNum, @@servername as SQLInstance, name FROM sys.sql_logins 
WHERE PWDCOMPARE(name, password_hash) = 1 ;


--SCRIPT #43: Maintenance job history
select 43 as ScriptNum, @@servername as SQLInstance, replace(job_name,'-- ','') as job_name, run_datetime, run_duration, run_stat
from
(
    select job_name, run_datetime,
        SUBSTRING(run_duration, 1, 2) + ':' + SUBSTRING(run_duration, 3, 2) + ':' +
        SUBSTRING(run_duration, 5, 2) AS run_duration, 
        case when run_status = 0 then 'Failed' when run_status = 1 then 'Succeeded' else 'Other' end as run_stat
    from
    (
        select distinct
            j.name as job_name, 
            run_datetime = CONVERT(DATETIME, RTRIM(run_date)) +  
                (run_time * 9 + run_time % 10000 * 6 + run_time % 100 * 10) / 216e4,
            run_duration = RIGHT('000000' + CONVERT(varchar(6), run_duration), 6), run_status
        from msdb..sysjobhistory h
        inner join msdb..sysjobs j
        on h.job_id = j.job_id
    ) t
) t
where run_datetime >= getdate() - 30
  and (job_name in ('-- Dell DBA: Weekly Maintenance')
  or job_name like '-- DellDBA - DBCC CHECKDB%'
  or job_name like '-- DellDBA - DBCC ALTERINDEX%'
  or job_name like '-- DellDBA - DBCC UPDATESTATS%')
order by replace(job_name,'-- ',''), run_datetime

