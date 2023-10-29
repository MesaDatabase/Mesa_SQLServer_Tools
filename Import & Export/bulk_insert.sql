BULK
INSERT msdb.dbo.tmp1
FROM 'c:\temp\input.txt'
WITH
(
FIELDTERMINATOR = ',',
ROWTERMINATOR = '\n'
)
GO
