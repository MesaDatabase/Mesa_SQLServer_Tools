


select [ETL].[usp_StgTableColumns_Get]('Staging.AkcLendingLIABILITY')
select [ETL].[usp_StgTableColumns_Get]('Akc.FactLendingApplicationLiability')

select 
  schema_name(o.schema_id) as SchemaName,
  object_name(c.object_id) as TableName,
  column_id as ColumnId,
  c.name as ColumnName,
  t.name as ColumnType,
  c.name + ',' as ColumnNameWithComma,

  c.name + ' = source.' + c.name + ',',
  '[' + c.name + ']' + ' = source.[' + c.name + '],' as WithBrackets,
  c.name + 
		' ' +
		case when t.name in ('char','varchar') then t.name + '(' + cast(c.max_length as varchar(10)) + ')' else t.name end + 
		' ' +
		case when c.is_nullable = 1 then 'NULL' else 'NOT NULL' end +
		',',
  c.name + 
		' ' +
		case when t.name in ('char','varchar') then t.name + '(' + cast(c.max_length as varchar(10)) + ')' else t.name end + 
		','
  --select top 10 o.*
from sys.all_columns as c
  join sys.types as t on c.user_type_id = t.user_type_id
  join sys.objects as o on c.object_id = o.object_id
where schema_name(o.schema_id) + '.' + object_name(o.object_id) in ('Akc.FactLendingApplicationLiability')
order by 1,2,3

