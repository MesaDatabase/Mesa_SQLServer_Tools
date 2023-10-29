set nocount on

declare @db table (DatabaseName varchar(100))
insert into @db
select s1.name
from master.sys.databases as s1
  left join sys.dm_hadr_database_replica_states as h1 on s1.database_id = h1.database_id
where state_desc = 'ONLINE'
  and s1.name not in ('master','msdb','tempdb')
  and isnull(h1.is_primary_replica,1) = 1

if object_id('tempdb..#tStats') is not null
begin
    drop table #tStats
end
create table #tStats (DatabaseName varchar(100), ObjectId int, TblName varchar(255), IdxName varchar(255), StatsDate datetime, IdxId int, RowCnt int, RowModCnt int, ChangedRowsRatio numeric(18,4), IsAutoUpdateOff int)


declare @dbname0 varchar(100), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @db)
begin
set @dbname0 = (select top 1 DatabaseName from @db)

set @sql = 'use [' + @dbname0 + '];
insert into #tStats
SELECT 
''' + @dbname0 + '''
,ssi.id
, object_name(ssi.id) AS tblName
, ssi.name as idxName
, stats_date(ssi.id,ssi.indid) as StatsDate
, ssi.indid
, ssi.rowcnt
, ssi.rowmodctr
, cast(ssi.rowmodctr as decimal)/cast(ssi.rowcnt as decimal) as ChangedRowsRatio
, ss.no_recompute AS IsAutoUpdateOff
FROM sys.sysindexes ssi left join sys.stats ss
ON ssi.name = ss.name
WHERE ssi.id > 100
AND indid > 0
AND ssi.rowcnt > 500
AND (stats_date(ssi.id,ssi.indid) is null OR stats_date(ssi.id,ssi.indid) < getdate() - 10)
AND ssi.rowmodctr > 0'

exec(@sql)

delete from @db where DatabaseName = @dbname0
end 

select *,
'use [' + DatabaseName + ']; UPDATE STATISTICS ' + TblName + ' ' + IdxName + ';' as UpdateStatsStatement
from #tStats
order by DatabaseName, TblName

if object_id('tempdb..#tStats') is not null
begin
    drop table #tStats
end
