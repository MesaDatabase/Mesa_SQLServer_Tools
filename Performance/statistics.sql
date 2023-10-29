--How are statistics created?
Statistics are automatically created for each index key you create.
If the database setting autocreate stats is on, then SQL Server will automatically create statistics for non-indexed columns that are used in queries.
Or you can manually create statistics
	CREATE STATISTICS <stat_name>
	ON <table_name>(<column_name>)
	WITH FULLSCAN;

--How can I see what statistics look like?
 - through ssms
 - tsql
	DBCC SHOW_STATISTICS('mapDevice2SoftwareProducts','IDX_DeviceSoftwareProducts_ITAssetObjectID')
	WITH HISTOGRAM

--How are statistics updated?
The default settings in SQL Server are to autocreate and autoupdate statistics.
	Auto Update Statistics basically means, if there is an incoming query but statistics are stale, SQL Server will update statistics first before it generates an execution plan.
	Auto Update Statistics Asynchronously on the other hand means, if there is an incoming query but statistics are stale, SQL Server uses the stale statistics to generate the execution plan, then updates the statistics afterwards.
Manually update statistics, you can use either 
	sp_updatestats or 
	UPDATE STATISTICS <statistics name>

--How do we know statistics are being used?
One good check you can do is when you generate execution plans for your queries:
	check out your “Actual Number of Rows” and “Estimated Number of Rows”. 
If these numbers are (consistently) fairly close, then most likely your statistics are up-to-date and used by the optimizer for the query. If not, time for you to re-check your statistics create/update frequency.


--When are statistics updated?
If the table has no rows, statistics is updated when there is a single change in table.
If the number of rows in a table is less than 500, statistics is updated for every 500 changes in table.
If the number of rows in table is more than 500, statistics is updated for every 500+20% of rows changes in table.




--sites to read more
http://msdn.microsoft.com/en-us/library/dd535534.aspx
http://sqlblog.com/blogs/elisabeth_redei/archive/2009/03/01/lies-damned-lies-and-statistics-part-i.aspx
http://sqlblog.com/blogs/elisabeth_redei/archive/2009/08/10/lies-damned-lies-and-statistics-part-ii.aspx
http://sqlblog.com/blogs/elisabeth_redei/archive/2009/12/17/lies-damned-lies-and-statistics-part-iii-sql-server-2008.aspx
