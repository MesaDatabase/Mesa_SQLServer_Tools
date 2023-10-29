--=============================================================================
--      Setup
--=============================================================================    
USE TempDB     --DB that everyone has where we can cause no harm    
SET NOCOUNT ON --Supress the auto-display of rowcounts for appearance/speed
DECLARE @StartTime DATETIME    --Timer to measure total duration    
SET @StartTime = GETDATE() --Start the timer

--=============================================================================
--      Create and populate a Tally table
--=============================================================================
--===== Conditionally drop      
IF OBJECT_ID('dbo.Tally') IS NOT NULL         
DROP TABLE dbo.Tally

--===== Create and populate the Tally table on the fly 
SELECT TOP 11000 --equates to more than 30 years of dates        
	IDENTITY(INT,1,1) AS N   
INTO dbo.Tally  
FROM Master.dbo.SysColumns sc1,        
	Master.dbo.SysColumns sc2

--===== Add a Primary Key to maximize performance  
ALTER TABLE dbo.Tally    
ADD CONSTRAINT PK_Tally_N         
PRIMARY KEY CLUSTERED (N) 
WITH FILLFACTOR = 100

--===== Let the public use it  
GRANT SELECT, REFERENCES ON dbo.Tally TO PUBLIC

--===== Display the total duration 
SELECT STR(DATEDIFF(ms,@StartTime,GETDATE())) + ' Milliseconds duration'

select CHAR(N), N from Tally 
where char(N) between '0' and 'Z' collate SQL_Latin1_General_CP1_CI_AS 
  and N < 256 
order by CHAR(N) 