set nocount on

declare @t1 table (DatabaseName varchar(255))
insert into @t1
select name from master.dbo.sysdatabases 
where name not in ('master','model','msdb')

--pre-2012
create table #t2 (FileId int, FileSize bigint, StartOffset bigint, FSeqNo bigint, Status int, Parity int, CreateLSN varchar(50))
create table #t3 (DatabaseName varchar(255), FileId int, FileSize bigint, StartOffset bigint, FSeqNo bigint, Status int, Parity int, CreateLSN varchar(50))

--2012+
create table #t5 (RecoveryUnitId int, FileId int, FileSize bigint, StartOffset bigint, FSeqNo bigint, Status int, Parity int, CreateLSN varchar(50))
create table #t6 (DatabaseName varchar(255), RecoveryUnitId int, FileId int, FileSize bigint, StartOffset bigint, FSeqNo bigint, Status int, Parity int, CreateLSN varchar(50))

create table #t4 (DatabaseName varchar(255), FileId int, Status int, Row int)

declare @ver int
SELECT @ver = cast(master.dbo.fsplit('.',convert(char(2),SERVERPROPERTY('productversion')),1) as int)

declare @dbname varchar(255), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
  set @dbname = (select top 1 DatabaseName from @t1 t1)
  set @SQL='DBCC LOGINFO ([' + @dbname + ']) WITH TABLERESULTS, NO_INFOMSGS'

  if @ver < 11
  begin

	insert into #t2
	exec(@SQL)
	insert into #t3 select @dbname, * from #t2

	insert into #t4
	select @dbname, FileId, Status, ROW_NUMBER() over(order by @dbname, StartOffset) from #t2
  end

  if @ver >= 11
  begin
	insert into #t5
	exec(@SQL)
	insert into #t6 select @dbname, * from #t5

	insert into #t4
	select @dbname, FileId, Status, ROW_NUMBER() over(order by @dbname, StartOffset) from #t5
  end

delete from @t1 where DatabaseName = @dbname
delete from #t2
delete from #t5
end

select @@SERVERNAME, #t4.DatabaseName, #t4.FileId, a.vlf_count, b.last_stat2_row from #t4 
  join (select DatabaseName, COUNT(1) as vlf_count from #t3 group by DatabaseName) a on #t4.DatabaseName = a.DatabaseName
  join (select DatabaseName, MAX(Row) as last_stat2_row from #t4 where Status = 2 group by DatabaseName) b on #t4.DatabaseName = b.DatabaseName and #t4.Row = b.last_stat2_row
where Status = 2
union
select @@SERVERNAME, #t4.DatabaseName, #t4.FileId, a.vlf_count, b.last_stat2_row from #t4 
  join (select DatabaseName, COUNT(1) as vlf_count from #t6 group by DatabaseName) a on #t4.DatabaseName = a.DatabaseName
  join (select DatabaseName, MAX(Row) as last_stat2_row from #t4 where Status = 2 group by DatabaseName) b on #t4.DatabaseName = b.DatabaseName and #t4.Row = b.last_stat2_row
where Status = 2

drop table #t2
drop table #t3
drop table #t4
drop table #t5
drop table #t6
