
if object_id('tempdb..#tAllCols') is not null drop table #tAllCols
if object_id('tempdb..#tSens') is not null drop table #tSens
if object_id('tempdb..#tSensDis') is not null drop table #tSensDis


create table #tAllCols (SchemaName varchar(255), TableName varchar(255), ColumnId int, ColumnName varchar(255), ColumnType varchar(255))
create table #tSens (SchemaName varchar(255), TableName varchar(255), ColumnId int, ColumnName varchar(255), Label sql_variant, LabelId sql_variant, InfoType sql_variant, InfoTypeId sql_variant, [Rank] sql_variant, RankDesc varchar(8), DropStmt varchar(max), CreateStmt varchar(max))
create table #tSensDis (SchemaName varchar(255), TableName varchar(255), ColumnId int, ColumnName varchar(255), CreateStmt varchar(max))



--all columns
insert into #tAllCols
select 
  schema_name(o.schema_id) as SchemaName,
  object_name(c.object_id) as TableName,
  column_id as ColumnId,
  c.name as ColumnName,
  t.name as ColumnType
from sys.all_columns as c
  join sys.types as t on c.user_type_id = t.user_type_id
  join sys.objects as o on c.object_id = o.object_id
where 1=1
  and o.type = 'U'


--get and script out all sensitivity classification
insert into #tSens
select 
	schema_name(schema_id), 
	o.name, 
	c.column_id,
	c.name,
	label,
	label_id,
	information_type,
	information_type_id,
	[rank],
	rank_desc,
	'DROP SENSITIVITY CLASSIFICATION FROM ' + schema_name(schema_id) + '.' + o.name + '.' + c.name
,
	'ADD SENSITIVITY CLASSIFICATION TO ' + schema_name(schema_id) + '.' + o.name + '.' + c.name +
		' WITH (LABEL = ''' + cast(sc.label as varchar(255)) + ''', LABEL_ID = ''' + cast(sc.label_id as varchar(255)) + ''', INFORMATION_TYPE = ''' + cast(sc.information_type as varchar(255)) + ''', INFORMATION_TYPE_ID = ''' + cast(sc.information_type_id as varchar(255)) + ''', RANK = ' + rank_desc + ');'
	
from sys.sensitivity_classifications as sc
  join sys.objects as o on sc.major_id = o.object_id
  join sys.all_columns as c on o.object_id = c.object_id and sc.minor_id = c.column_id


insert into #tSensDis
select 
	schema_name(schema_id), 
	o.name,
	c.column_id,
	c.name,
	'EXECUTE sp_addextendedproperty @name = N''sys_data_classification_recommendation_disabled'', @value = 1, @level0type = N''SCHEMA'', @level0name = N''' + schema_name(schema_id) + ''', @level1type = N''TABLE'', @level1name = N''' + o.name + ''', @level2type = N''COLUMN'', @level2name = N''' + c.name + ''';'
	--select *
from sys.extended_properties as ep
  join sys.objects as o on ep.major_id = o.object_id
  join sys.all_columns as c on o.object_id = c.object_id and ep.minor_id = c.column_id
  left join #tSens as s on schema_name(schema_id) = s.SchemaName and o.name = s.TableName and c.name = s.ColumnName
where ep.name = 'sys_data_classification_recommendation_disabled'
  and value = 1
  and s.ColumnId is null

--select * from #tAllCols
--select * from #tSens
--select * from #tSensDis


--columns with no sensitivity classification enabled or disabled
select *,

	'EXECUTE sp_addextendedproperty @name = N''sys_data_classification_recommendation_disabled'', @value = 1, @level0type = N''SCHEMA'', @level0name = N''' + a.SchemaName + ''', @level1type = N''TABLE'', @level1name = N''' + a.TableName + ''', @level2type = N''COLUMN'', @level2name = N''' + a.ColumnName + ''';' AS DisableSensRecommendation

from #tAllCols as a
  left join #tSens as s on a.SchemaName = s.SchemaName and a.TableName = s.TableName and a.ColumnName = s.ColumnName
  left join #tSensDis as d on a.SchemaName = d.SchemaName and a.TableName = d.TableName and a.ColumnName = d.ColumnName
where 1=1
  --and a.SchemaName not in ('ETL','Healthcheck','Rpt')
  and a.TableName = 'DimTracking'
  and s.ColumnId is null
  and d.ColumnId is null


EXECUTE sp_addextendedproperty @name = N'sys_data_classification_recommendation_disabled', @value = 1, @level0type = N'SCHEMA', @level0name = N'Episys', @level1type = N'TABLE', @level1name = N'DimTracking', @level2type = N'COLUMN', @level2name = N'FactAccountId';


SELECT distinct session_server_principal_name 
FROM sys.fn_get_audit_file ('https://pproddb.blob.core.windows.net/sqldbauditlogs/prduseamdapsqlsrv/prduseamdapsqldbDW/SqlDbAuditing_Audit/2020-05-22',default,default)
WHERE 1=1
 and statement like '%sp_addextendedproperty%'


