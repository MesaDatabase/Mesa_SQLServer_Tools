-- Query to get the user associated schema
select * from information_schema.schemata
where schema_owner = 'dbo'

--Query to fix the error Msg 15138
USE [DB1]
GO
ALTER AUTHORIZATION ON ROLE::[db_owner] TO [dbo]
GO

USE [DB1]
GO
/****** Object:  User [dbo]    Script Date: 8/17/2015 4:02:31 PM ******/
DROP USER [dbo]
GO
