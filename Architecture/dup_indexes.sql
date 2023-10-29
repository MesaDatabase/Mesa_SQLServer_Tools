-- exact duplicates
declare @t0 table (DbName varchar(255))
insert into @t0
select name from sys.databases
where database_id > 4

create table #t1  (ObjectId bigint, IndexId int, Name varchar(255), Columns varchar(100), InclCols varchar(100))
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

select * from #t2

drop table #t1
drop table #t2



-- Overlapping indxes
-- exact duplicates
declare @t0 table (DbName varchar(255))
insert into @t0
select name from sys.databases
where database_id > 4

create table #t1  (ObjectId bigint, IndexId int, Name varchar(255), Columns varchar(100))
create table #t2 (DbName varchar(255), TableName varchar(255), IndexName varchar(255), PartialDupName varchar(255))

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
	for xml path(''''))
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
	and (t1.Columns like t2.Columns + ''%'' 
	or t2.Columns like t1.Columns + ''%'')'

  exec(@sql)
  
  delete from @t0 where DbName = @db
  truncate table #t1
end

select * from #t2

drop table #t1
drop table #t2
