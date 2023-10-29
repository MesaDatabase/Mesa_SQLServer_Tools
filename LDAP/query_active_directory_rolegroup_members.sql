/***********************************************************
-- Description  : Get members of all specified groups
-- Notes		: This can take a few minutes to run as it runs a dsquery for each group
-- Modified		: 
***********************************************************/


SET NOCOUNT ON


--DECLARE variables
DECLARE @gName varchar(255)
DECLARE @gId int
DECLARE @sql varchar(1000)


--drop temp tables
IF object_id('tempdb..#t1') IS NOT NULL DROP TABLE #t1
IF object_id('tempdb..#tRole') IS NOT NULL DROP TABLE #tRole
IF object_id('tempdb..#t2') IS NOT NULL DROP TABLE #t2
IF object_id('tempdb..#tRoleMembers') IS NOT NULL DROP TABLE #tRoleMembers


--create temp tables
CREATE TABLE #t1 (RoleOutput varchar(1000))
CREATE TABLE #tRole (RoleId int identity(1,1), RoleGroupName varchar(255), IsComplete bit)
CREATE TABLE #t2 (MemberOutput varchar(1000))
CREATE TABLE #tRoleMembers (RoleMemberId int identity(1,1), RoleId int, MemberName varchar(255))


--get role groups
SET @sql = 'EXEC MASTER..XP_CMDSHELL ''dsquery group -name "Role*" -limit 1000'''
INSERT INTO #t1
EXEC(@sql)

INSERT into #tRole (RoleGroupName)
SELECT master.dbo.fSplit(',',master.dbo.fSplit('=',RoleOutput,2),1)
FROM #t1
WHERE master.dbo.fSplit(',',master.dbo.fSplit('=',RoleOutput,2),1) <> ''
ORDER BY 1

--select * from #tRole

--get group membership
WHILE EXISTS (SELECT TOP 1 * FROM #tRole WHERE IsComplete IS NULL)
BEGIN
	SELECT TOP 1 @gName = RoleGroupName, @gId = RoleId FROM #tRole WHERE IsComplete IS NULL

	--SELECT @gName

	SET @sql = 'EXEC MASTER..XP_CMDSHELL ''dsquery group -name "' + @gName + '" | dsget group -members'''
  
	--print @sql

	INSERT into #t2
	EXEC(@sql)

	INSERT into #tRoleMembers (RoleId, MemberName)
	SELECT @gId, REPLACE(master.dbo.fSplit(',',MemberOutput,1),'"CN=','')
	FROM #t2
	WHERE MemberOutput IS NOT NULL

	UPDATE #tRole SET IsComplete = 1 WHERE RoleGroupName = @gName
	DELETE FROM #t2
END

SELECT m.RoleMemberId, r.RoleId, r.RoleGroupName, MemberName
FROM #tRole AS r
  LEFT JOIN #tRoleMembers AS m ON r.RoleId = m.RoleId
