CREATE TABLE #tablelist (table_name VARCHAR(100))

INSERT INTO #tablelist --find all tables in the database
SELECT table_name FROM information_schema.tables WHERE table_type = 'BASE TABLE' ORDER BY table_name

--create a cursor loop over temp table to get all meta data
DECLARE @table_name VARCHAR(20)
DECLARE table_cursor CURSOR FOR
SELECT table_name from #tablelist
OPEN table_cursor
WHILE @@FETCH_STATUS = 0
BEGIN
	FETCH NEXT FROM table_cursor into @table_name

--List Column and extended properties
	SELECT table_name, column_name, data_type, cast(des.value AS VARCHAR(400)) AS col_desc
	FROM
		information_schema.columns col LEFT OUTER JOIN
		::fn_listextendedproperty(NULL, 'user','dbo','table',@table_name,'column', default) des
			ON col.column_name = des.objname COLLATE latin1_general_ci_ai
	WHERE table_name = @table_name
	ORDER BY ordinal_position
END
CLOSE table_cursor
DEALLOCATE table_cursor
DROP TABLE #tablelist