select o.name, i.object_id, i.name, i.type_desc from sys.indexes i
  join sys.objects o on i.object_id = o.object_id
where is_hypothetical = 1
