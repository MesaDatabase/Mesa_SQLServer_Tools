CREATE TABLE #temp (
       Id INT IDENTITY(1,1), 
       ParentObject VARCHAR(255),
       [Object] VARCHAR(255),
       Field VARCHAR(255),
       [Value] VARCHAR(255)
)

INSERT INTO #temp
EXECUTE SP_MSFOREACHDB'DBCC DBINFO ( ''?'') WITH TABLERESULTS';

;WITH CHECKDB1 AS
(
    SELECT [Value],ROW_NUMBER() OVER (ORDER BY ID) AS rn1 FROM #temp WHERE Field IN ('dbi_dbname'))
    ,CHECKDB2 AS ( SELECT [Value], ROW_NUMBER() OVER (ORDER BY ID) AS rn2 FROM #temp WHERE Field IN ('dbi_dbccLastKnownGood')
)      
SELECT CHECKDB1.Value AS DatabaseName
        , CHECKDB2.Value AS LastRanDBCCCHECKDB
FROM CHECKDB1 JOIN CHECKDB2
ON rn1 =rn2

DROP TABLE #temp