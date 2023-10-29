SELECT name ,
index_id ,
type ,
type_desc ,
is_disabled
FROM sys.indexes
where is_disabled = 1