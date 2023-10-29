--get and script out all sensitivity classification
select sc.*, schema_name(schema_id), o.name, c.name
,
	'DROP SENSITIVITY CLASSIFICATION FROM ' + schema_name(schema_id) + '.' + o.name + '.' + c.name
,
	'ADD SENSITIVITY CLASSIFICATION TO ' + schema_name(schema_id) + '.' + o.name + '.' + c.name +
		' WITH (LABEL = ''' + cast(sc.label as varchar(255)) + ''', LABEL_ID = ''' + cast(sc.label_id as varchar(255)) + ''', INFORMATION_TYPE = ''' + cast(sc.information_type as varchar(255)) + ''', INFORMATION_TYPE_ID = ''' + cast(sc.information_type_id as varchar(255)) + ''', RANK = ' + rank_desc + ');'
	
from sys.sensitivity_classifications as sc
  join sys.objects as o on sc.major_id = o.object_id
  join sys.all_columns as c on o.object_id = c.object_id and sc.minor_id = c.column_id


