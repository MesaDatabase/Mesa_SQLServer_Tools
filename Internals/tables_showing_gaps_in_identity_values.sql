/* Issue is that there is a reported SQL 2012 bug with int and bigint identity columns:
 * must have an identity on int or bigint column
 * affects tables whose max identity value is greater than 100
 * sql server restart causes the identity value to skip 1000 values
 * no comment yet from MS
 * issue first noticed in CMCDB_PROD on 11/21/12
*/

--identifies tables having int or bigint identity column that has gaps nearing 1000
declare @temp table (SchemaName varchar(255), TableName varchar(255), ColumnName varchar(255), DataType varchar(100))
insert into @temp
select s.name, object_name(c.object_id), c.name, t.name
--select *
from sys.columns c
  join sys.types t on c.system_type_id = t.system_type_id
  join sys.objects o on c.object_id = o.object_id
  join sys.schemas s on o.schema_id = s.schema_id
where c.is_identity = 1
  and o.is_ms_shipped = 0
  --and object_name(c.object_id) = 'AppSetting_Audit'
order by object_name(c.object_id)

declare @sql varchar(4000)
declare @SchemaName varchar(255)
declare @TableName varchar(255)
declare @ColumnName varchar(255)

if exists (select * from tempdb.sys.objects where name like '#t1%') drop table #t1
create table #t1 (TableName varchar(255), RowCountValue int, MaxId int)

while exists (select top 1 * from @temp t)
begin
	set @TableName = (select top 1 TableName from @temp t)
	set @SchemaName = (select top 1 SchemaName from @temp t where TableName = @TableName)
	set @ColumnName = (select top 1 ColumnName from @temp t where TableName = @TableName)
	set @sql = 'insert into #t1 select ''' + @TableName + ''', count(1), max(' + @ColumnName + ') from ' + @SchemaName +'.' + @TableName
	exec(@sql)
	delete from @temp where TableName = @TableName
end

select * from #t1
where abs(RowCountValue - MaxId) >= 998
if exists (select * from tempdb.sys.objects where name like '#t1%') drop table #t1



--tables where we see gap in identity value 11/21
--select * from OppPurchaseAttributeDetail
-- 3216 -> 4215

--select * from OppPurchaseDetail
-- 733 -> 1733

