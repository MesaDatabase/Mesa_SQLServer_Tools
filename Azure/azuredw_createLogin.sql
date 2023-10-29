----SQL authentication
--connect to master db first
create login LoadUser with password = '#hash';

--connect to user db next
create user LoadUser for login LoadUser;

ALTER ROLE db_owner ADD MEMBER LoadUser;


----Azure AD authentication
--https://docs.microsoft.com/en-us/azure/sql-database/sql-database-aad-authentication-configure
--connect to master db first
CREATE USER [user@domain.onmicrosoft.com] FROM  EXTERNAL PROVIDER 
GO

--connect to user db next
CREATE USER [user@domain..onmicrosoft.com] FROM  EXTERNAL PROVIDER 
GO

ALTER ROLE db_owner ADD MEMBER [user@domain..onmicrosoft.com]



--create application role for viewing definition of views/sprocs
CREATE ROLE view_definition AUTHORIZATION dbo

GRANT VIEW DEFINITION TO view_definition;



ALTER ROLE view_definition ADD MEMBER [user@domain.onmicrosoft.com]
