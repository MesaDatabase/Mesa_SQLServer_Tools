--make a temp table to hold a list of table names
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
	--List Table extended properties
	SELECT * from ::fn_listextendedproperty ('MS_DESCRIPTION','user','dbo','table',@table_name,NULL,NULL)
END
CLOSE table_cursor
DEALLOCATE table_cursor
DROP TABLE #tablelist