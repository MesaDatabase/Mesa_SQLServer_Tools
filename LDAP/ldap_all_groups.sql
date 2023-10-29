CREATE TABLE #tmpADUsers (
SAMAccountName varchar(255) NOT NULL)
GO

/* AD is limited to send 1000 records in one batch. In an ADO interface you can define this batch size, not in OPENQUERY.
Because of this limitation, we just loop through the alphabet.
*/

DECLARE @cmdstr varchar(255)
DECLARE @nAsciiValue smallint
DECLARE @sChar char(1)

SELECT @nAsciiValue = 65

WHILE @nAsciiValue < 91
BEGIN

SELECT @sChar= CHAR(@nAsciiValue)

EXEC master..xp_sprintf @cmdstr OUTPUT, 'SELECT sAMAccountName FROM OPENQUERY( ADSI, ''SELECT sAMAccountName FROM ''''LDAP://DC=ufcunet,DC=ad''''WHERE objectClass = ''''Group'''' AND cn = ''''%s*'''''' )', @sChar

INSERT #tmpADUsers
EXEC( @cmdstr )

SELECT @nAsciiValue = @nAsciiValue + 1
END

select * from #tmpADUsers

DROP TABLE #tmpADUsers