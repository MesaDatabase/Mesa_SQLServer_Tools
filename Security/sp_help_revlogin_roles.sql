USE master
GO

IF OBJECT_ID ('sp_help_revlogin_roles') IS NOT NULL
	DROP PROCEDURE sp_help_revlogin_roles
GO
CREATE PROCEDURE sp_help_revlogin_roles
	@login_name sysname=NULL,
	@databases bit=1,
	@roles bit=1
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @name sysname
	DECLARE @role sysname
	DECLARE @type varchar (1)
	DECLARE @hasaccess int
	DECLARE @denylogin int
	DECLARE @is_disabled int
	DECLARE @PWD_varbinary  varbinary (256)
	DECLARE @PWD_string  varchar (514)
	DECLARE @SID_varbinary varbinary (85)
	DECLARE @SID_string varchar (514)
	DECLARE @is_policy_checked varchar (3)
	DECLARE @is_expiration_checked varchar (3)
	DECLARE @defaultdb sysname
	DECLARE @defaultlang sysname
	DECLARE @crlf varchar(2)
	DECLARE @return int

	SET @crlf = CHAR(13) + CHAR(10)

	PRINT '/* sp_help_revlogin script '
	PRINT '** Generated ' + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
	PRINT ''
	PRINT '/* Begin Script Logins ------------------------- */'

	IF (@login_name IS NULL)
	BEGIN
		DECLARE rev_cursor CURSOR STATIC READ_ONLY FOR
			SELECT p.sid, p.name, p.type, p.is_disabled, ISNULL(p.default_database_name, 'master'), ISNULL(p.default_language_name, 'us_english'), l.hasaccess, l.denylogin
			FROM sys.server_principals p
			LEFT JOIN sys.syslogins l
				ON ( l.name = p.name )
			WHERE p.type IN ( 'S', 'G', 'U' )
				AND p.name <> 'sa'
	END
	ELSE
	BEGIN
		DECLARE rev_cursor CURSOR STATIC READ_ONLY FOR
			SELECT p.sid, p.name, p.type, p.is_disabled, ISNULL(p.default_database_name, 'master'), ISNULL(p.default_language_name, 'us_english'), l.hasaccess, l.denylogin
			FROM sys.server_principals p
			LEFT JOIN sys.syslogins l
				ON ( l.name = p.name )
			WHERE p.type IN ( 'S', 'G', 'U' )
				AND p.name = @login_name
	END

	OPEN rev_cursor

	FETCH NEXT FROM rev_cursor
		INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @defaultlang, @hasaccess, @denylogin

	IF (@@FETCH_STATUS = -1)
	BEGIN
		PRINT 'No login(s) found.'
		SELECT @return = -1
		GOTO Quit
	END

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SELECT @name=LTRIM(RTRIM(@name))
		PRINT '-- Login: ' + @name
		IF (@type IN ( 'G', 'U'))
		BEGIN -- NT authenticated account/group
			PRINT 'IF NOT EXISTS ( SELECT * FROM sys.server_principals WHERE name = ''' + @name + ''' )'
			PRINT '	CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'
		END
		ELSE BEGIN -- SQL Server authentication
			-- obtain password and sid
			SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )
			EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT
			EXEC sp_hexadecimal @SID_varbinary, @SID_string OUT

			-- obtain password policy state
			SELECT @is_policy_checked =
				CASE is_policy_checked
					WHEN 1 THEN 'ON'
					WHEN 0 THEN 'OFF'
					ELSE NULL
				END
			FROM sys.sql_logins
			WHERE name = @name

			SELECT @is_expiration_checked =
				CASE is_expiration_checked
					WHEN 1 THEN 'ON'
					WHEN 0 THEN 'OFF'
					ELSE NULL
				END
			FROM sys.sql_logins
			WHERE name = @name

			PRINT
				'IF NOT EXISTS ( SELECT * FROM sys.server_principals WHERE name = ''' + @name + ''' )' + @crlf +
				'	CREATE LOGIN ' + QUOTENAME( @name ) + @crlf +
				'		WITH PASSWORD = ' + @PWD_string + ' HASHED, ' + @crlf +
				'		SID = ' + @SID_string + ', ' + @crlf +
				'		DEFAULT_LANGUAGE = [' + @defaultlang + ']' +
				CASE WHEN ( @is_policy_checked IS NOT NULL ) THEN ',' + @crlf + '		CHECK_POLICY = ' + @is_policy_checked END +
				CASE WHEN ( @is_expiration_checked IS NOT NULL ) THEN ',' + @crlf + '		CHECK_EXPIRATION = ' + @is_expiration_checked END +
				';'
		END

		IF (@denylogin = 1)
		BEGIN -- login is denied access
			PRINT 'DENY CONNECT SQL TO ' + QUOTENAME( @name )
		END
		ELSE IF (@hasaccess = 0)
		BEGIN -- login exists but does not have access
			PRINT 'REVOKE CONNECT SQL TO ' + QUOTENAME( @name )
		END
		IF (@is_disabled = 1)
		BEGIN -- login is disabled
			PRINT 'ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'
		END

		PRINT ' '
		PRINT ' '
		FETCH NEXT FROM rev_cursor
			INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @defaultlang, @hasaccess, @denylogin
	END
	PRINT '/* End Script Logins ------------------------- */'
	PRINT ' '
	PRINT ' '

	IF @databases=1
	BEGIN
		FETCH FIRST FROM rev_cursor
			INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @defaultlang, @hasaccess, @denylogin
		PRINT '/* Begin Script Default Databases ------------------------- */'
		WHILE (@@FETCH_STATUS=0)
		BEGIN
			PRINT '-- Login: ' + @name
			PRINT 'IF EXISTS ( SELECT * FROM sys.server_principals WHERE name = ''' + @name + ''' )'
			PRINT '	ALTER LOGIN ' + QUOTENAME( @name ) + ' WITH DEFAULT_DATABASE = [' + @defaultdb + ']'
			PRINT ' '

			FETCH NEXT FROM rev_cursor
				INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @defaultlang, @hasaccess, @denylogin
		END
		PRINT '/* End Script Default Databases ------------------------- */'
		PRINT ' '
		PRINT ' '
	END
	CLOSE rev_cursor
	DEALLOCATE rev_cursor

	IF @roles=1
	BEGIN
		PRINT '/* Begin Script Roles ------------------------- */'
		DECLARE rev_cursor CURSOR STATIC READ_ONLY FOR
			SELECT p1.name role_principal_name, p2.name member_principal_name FROM sys.server_role_members rm
			INNER JOIN sys.server_principals p1
				ON p1.principal_id=rm.role_principal_id
			INNER JOIN sys.server_principals p2
				ON p2.principal_id=rm.member_principal_id
			WHERE
				p2.type IN ( 'S', 'G', 'U' )
				AND p2.name <> 'sa'
			ORDER BY p2.principal_id
		OPEN rev_cursor

		FETCH NEXT FROM rev_cursor
			INTO @role, @name
		IF (@@FETCH_STATUS = -1)
		BEGIN
			PRINT '-- No role member(s) found.'
		END

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			PRINT 'EXEC master.dbo.sp_addsrvrolemember @loginame=''' + @name + ''', @rolename=''' + @role + ''''

			FETCH NEXT FROM rev_cursor
				INTO @role, @name
		END
		PRINT '/* End Script Roles ------------------------- */'
		PRINT ' '
		PRINT ' '

		CLOSE rev_cursor
		DEALLOCATE rev_cursor
	END

	SELECT @return = 0

	Quit:
		RETURN @return

END
GO