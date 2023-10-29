set nocount on

declare @t1 table (DatabaseName varchar(100))
insert into @t1
select name from master.sys.databases 
where state_desc = 'ONLINE'
  and name not in ('master','msdb','model')
  --and name = 'CI'

create table #t2 (DatabaseName varchar(100), IndexId int, ObjectName varchar(255), IndexName varchar(255), PageSplits int, PageAllocationCausedByPageSplit int)

declare @dbname varchar(100), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
--USE master;
EXEC(N'USE [' + @dbname + N']; EXEC(''insert into #t2 
select db_name(), 
  IOS.INDEX_ID,
  O.NAME AS OBJECT_NAME,
  I.NAME AS INDEX_NAME,
  IOS.LEAF_ALLOCATION_COUNT AS PAGE_SPLIT_FOR_INDEX,
  IOS.NONLEAF_ALLOCATION_COUNT PAGE_ALLOCATION_CAUSED_BY_PAGESPLIT
FROM SYS.DM_DB_INDEX_OPERATIONAL_STATS(DB_ID(DB_NAME()),NULL,NULL,NULL) AS IOS
  JOIN SYS.INDEXES AS I ON IOS.INDEX_ID=I.INDEX_ID AND IOS.OBJECT_ID = I.OBJECT_ID
  JOIN SYS.OBJECTS AS O ON IOS.OBJECT_ID=O.OBJECT_ID
WHERE O.TYPE_DESC=''''USER_TABLE'''';'');');
delete from @t1 where DatabaseName = @dbname
end 

select @@servername as server,
 *
from #t2

--drop table #t2
