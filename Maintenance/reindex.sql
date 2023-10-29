ALTER INDEX [index_startdate] ON DB].[dbo].[table]
REBUILD PARTITION=4 WITH (SORT_IN_TEMPDB = ON)