--------------------------------------------- Prep ---------------------------------------------
USE master;
IF db_id('CorruptMe') IS NOT NULL
BEGIN
	ALTER DATABASE CorruptMe SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE CorruptMe
END	

CREATE DATABASE CorruptMe;
GO

--Make sure we're using CHECKSUM as our page verify option
ALTER DATABASE CorruptMe SET PAGE_VERIFY CHECKSUM;

USE CorruptMe;

--Insert some dead birdies
CREATE TABLE dbo.DeadBirdies (
    birdId INT NOT NULL ,
    birdName NVARCHAR(256) NOT NULL,
    rowCreatedDate DATETIME2(0) NOT NULL )

;WITH
  Pass0 AS (SELECT 1 AS C UNION ALL SELECT 1),
  Pass1 AS (SELECT 1 AS C FROM Pass0 AS A, Pass0 AS B),
  Pass2 AS (SELECT 1 AS C FROM Pass1 AS A, Pass1 AS B),
  Pass3 AS (SELECT 1 AS C FROM Pass2 AS A, Pass2 AS B),
  Pass4 AS (SELECT 1 AS C FROM Pass3 AS A, Pass3 AS B),
  Pass5 AS (SELECT 1 AS C FROM Pass4 AS A, Pass4 AS B),
  Tally AS (SELECT ROW_NUMBER() OVER(ORDER BY C) AS NUMBER FROM Pass5)
INSERT dbo.DeadBirdies (birdId, birdName, rowCreatedDate)
SELECT NUMBER AS birdId ,
    'Tweetie' AS birdName ,
    DATEADD(mi, NUMBER, '2000-01-01')
FROM Tally
WHERE NUMBER <= 500000

--Cluster on BirdId
CREATE UNIQUE CLUSTERED INDEX cxBirdsBirdId ON dbo.DeadBirdies(BirdId)
--Create a nonclustered index on BirdName
CREATE NONCLUSTERED INDEX ncBirds ON dbo.DeadBirdies(BirdName)
GO



--------------------------------------------- Find page to corrupt ---------------------------------------------
--get physical file name to corrupt
SELECT physical_name FROM sys.master_files WHERE name='CorruptMe';
--C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\CorruptMe.mdf

--show info on index to choose page to corrupt, select PagePID with PageType = 2
--third parameter is index id, can use 1 for clustered index
DBCC IND ('CorruptMe', 'DeadBirdies', 2) --272

--figure out starting offset of page to corrupt
SELECT 272*8192 AS [My Offset]
--2228224

--show info on page
DBCC TRACEON (3604);
GO
DBCC PAGE('CorruptMe', 1,272,3);

--set db to be corrupted offline
ALTER DATABASE CorruptMe SET OFFLINE;

--start hex editor, open db file, Ctrl+G paste in offset, search in decimal
--change one character in right pane, save and close file

--set corrupted db online
ALTER DATABASE CorruptMe SET ONLINE;

--run query that uses corrupted non-clustered index
Use CorruptMe;
SELECT birdName FROM dbo.deadBirdies;

--or use this to see corrupted page, shows object id of table and index
DBCC CHECKDB('CorruptMe')


--------------------------------------------- Fix ---------------------------------------------
USE [CorruptMe];
DROP INDEX [ncBirds] ON [dbo].[DeadBirdies];
