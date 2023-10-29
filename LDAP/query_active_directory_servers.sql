CREATE TABLE #tmpADComputers
( DNSHostName varchar(255),
CreateDateTime varchar(255),
operatingSystem varchar(255))
GO

/* AD is limited to send 1000 records in one batch. In an ADO interface you can define this batch size, not in OPENQUERY.
Because of this limitation, we just loop through the alphabet.
*/

DECLARE @cmdstr varchar(2000)
DECLARE @nAsciiValue smallint
DECLARE @sChar char(1)

SELECT @nAsciiValue = 65

--WHILE @nAsciiValue < 66
WHILE @nAsciiValue < 91
BEGIN

SELECT @sChar= CHAR(@nAsciiValue)

EXEC master..xp_sprintf @cmdstr OUTPUT, 'SELECT DNSHostname, whenCreated, operatingSystem FROM OPENQUERY( ADSI, ''SELECT DNSHostname, whenCreated, operatingSystem FROM ''''LDAP://OU=Servers,DC=ufcunet,DC=ad''''WHERE objectClass = ''''Computer'''' AND DNSHostname = ''''%s*'''''' )', @sChar
print(@cmdstr)

INSERT #tmpADComputers
EXEC( @cmdstr )

SELECT @nAsciiValue = @nAsciiValue + 1
END

select * from #tmpADComputers

DROP TABLE #tmpADComputers