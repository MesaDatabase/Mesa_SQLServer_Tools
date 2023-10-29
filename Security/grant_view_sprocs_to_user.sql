
set nocount on

declare @login varchar(255)

if @login is null
set @login = 'domain\Role-1'

declare @t1 table (SchemaName varchar(255), ObjectName varchar(255), ObjectType char(3))
insert into @t1
select schema_name(schema_id), name, type
--select *
from sys.objects 
where is_ms_shipped = 0
  and type in ('P')

declare @objName varchar(100), @SQL varchar (8000)

while exists (select top 1 * from @t1 t1 where ObjectType in ('P'))
begin
  set @objName = (select top 1 SchemaName + '].[' + ObjectName from @t1 t1 where ObjectType in ('P'))
  set @sql = ' GRANT VIEW DEFINITION ON [' + @objName + '] TO [' + @login + '];'
  print(@sql)
  --exec(@sql)

  delete from @t1 where SchemaName + '].[' + ObjectName = @objName
end 

