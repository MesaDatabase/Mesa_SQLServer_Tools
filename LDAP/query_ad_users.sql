/***********************************************************
-- Description  : Get members of all specified groups
-- Notes		: This can take a few minutes to run as it runs a dsquery for each group
-- Modified		: 
***********************************************************/


SET NOCOUNT ON


--DECLARE variables
DECLARE @user varchar(255)
DECLARE @gId int
DECLARE @sql varchar(1000)


--drop temp tables
IF object_id('tempdb..#t1') IS NOT NULL DROP TABLE #t1
IF object_id('tempdb..#tUser') IS NOT NULL DROP TABLE #tUser
IF object_id('tempdb..#t2') IS NOT NULL DROP TABLE #t2
IF object_id('tempdb..#t3') IS NOT NULL DROP TABLE #t3


--create temp tables
CREATE TABLE #t1 (MyOutput varchar(1000))
CREATE TABLE #tUser (UserId int identity(1,1), UserName varchar(255), DisplayName varchar(255), UserTitle varchar(255), UserNameComplete bit, TitleComplete bit)
CREATE TABLE #t2 (MyOutput varchar(1000))
CREATE TABLE #t3 (MyOutput varchar(1000))


--get users samid
SET @sql = 'EXEC MASTER..XP_CMDSHELL ''dsquery user OU=UFCU-Users,DC=ufcunet,DC=ad -limit 2000 | dsget user -display'''
INSERT INTO #t1
EXEC(@sql)

--select * from #t1

INSERT into #tUser (DisplayName)
SELECT ltrim(rtrim(MyOutput))
FROM #t1
WHERE MyOutput IS NOT NULL
  AND MyOutput NOT LIKE '%dsquery%'
  AND MyOutput NOT LIKE '%dsget%'
  AND MyOutput NOT LIKE '%display%'
  AND MyOutput NOT LIKE '%%''%'
ORDER BY 1

--select * from #tUser

--get user info
WHILE EXISTS (SELECT TOP 1 * FROM #tUser WHERE UserNameComplete IS NULL)
BEGIN
	SELECT TOP 1 @user = DisplayName, @gId = UserId FROM #tUser WHERE UserNameComplete IS NULL
	
	SET @sql = 'EXEC MASTER..XP_CMDSHELL ''dsquery user OU=UFCU-Users,DC=ufcunet,DC=ad -name "' + @user + '" | dsget user -samid'''
	print(@sql)
	
	INSERT into #t2
	EXEC(@sql)

	INSERT into #t3 (MyOutput)
	SELECT ltrim(rtrim(MyOutput))
	FROM #t2
	WHERE MyOutput IS NOT NULL
	  AND MyOutput NOT LIKE '%dsquery%'
	  AND MyOutput NOT LIKE '%dsget%'
	  AND MyOutput NOT LIKE '%samid%'

	UPDATE #tUser
	SET UserName = MyOutput
	FROM #t3
	WHERE DisplayName = @user

	UPDATE #tUser SET UserNameComplete = 1 WHERE DisplayName = @user
	DELETE FROM #t2
	DELETE FROM #t3
END

--select * from #tUser

WHILE EXISTS (SELECT TOP 1 * FROM #tUser WHERE TitleComplete IS NULL)
BEGIN
	SELECT TOP 1 @user = DisplayName, @gId = UserId FROM #tUser WHERE TitleComplete IS NULL

	SET @sql = 'EXEC MASTER..XP_CMDSHELL ''dsquery user OU=UFCU-Users,DC=ufcunet,DC=ad -name "' + @user + '" | dsget user -title'''
	--print(@sql)

	INSERT into #t2
	EXEC(@sql)

	INSERT into #t3 (MyOutput)
	SELECT ltrim(rtrim(MyOutput))
	FROM #t2
	WHERE MyOutput IS NOT NULL
	  AND MyOutput NOT LIKE '%dsquery%'
	  AND MyOutput NOT LIKE '%dsget%'
	  AND MyOutput NOT LIKE '%title%'

	UPDATE #tUser
	SET UserTitle = MyOutput
	FROM #t3
	WHERE DisplayName = @user

	UPDATE #tUser SET TitleComplete = 1 WHERE DisplayName = @user
	DELETE FROM #t2
	DELETE FROM #t3
END

select *
FROM #tUser