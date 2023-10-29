CREATE TABLE #tmpADUsers
( employeeId varchar(10) NULL,
SAMAccountName varchar(255) NOT NULL,
DisplayName varchar(255) NULL,
title varchar(255) NULL,
department varchar(255) NULL,
email varchar(255) NULL)
GO

/* AD is limited to send 1000 records in one batch. In an ADO interface you can define this batch size, not in OPENQUERY.
Because of this limitation, we just loop through the alphabet.
*/

DECLARE @cmdstr varchar(255)
DECLARE @nAsciiValue smallint
DECLARE @sChar char(1)
declare @sql varchar(2000)

SELECT @nAsciiValue = 65

WHILE @nAsciiValue < 91
BEGIN

SELECT @sChar= CHAR(@nAsciiValue)

set @sql = 'SELECT employeeId, SAMAccountName, DisplayName, title, department, mail FROM OPENQUERY( ADSI, ''SELECT title, SAMAccountName, DisplayName, employeeID, department, mail FROM ''''LDAP://OU=UFCU-Users,DC=ufcunet,DC=ad''''WHERE objectCategory = ''''Person'''' AND SAMAccountName = '''''+@sChar+'*'''''' )'

INSERT #tmpADUsers
EXEC( @sql )

SELECT @nAsciiValue = @nAsciiValue + 1
END

select * from #tmpADUsers

DROP TABLE #tmpADUsers