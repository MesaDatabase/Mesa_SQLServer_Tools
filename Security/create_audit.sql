-- Creates a server audit called "HIPPA_Audit" with a binary file as the target and no options.
CREATE SERVER AUDIT CMCDB_SIT_Audit
    TO FILE ( FILEPATH ='E:\MSSQL\AUDIT\' );

--Enable the Server Audit
ALTER SERVER AUDIT CMCDB_SIT_Audit
WITH (STATE = ON)
GO

--Create and enable the Server Audit Specification
CREATE SERVER AUDIT SPECIFICATION CMCDB_SIT_Audit_Spec
FOR SERVER AUDIT CMCDB_SIT_Audit
  --ADD (SUCCESSFUL_LOGIN_GROUP)
WITH (STATE = ON)
GO

--Create and enable the Database Audit Specification
USE CMCDB_SIT
GO  
CREATE DATABASE AUDIT SPECIFICATION CMCDB_SIT_AppSetting_Audit
FOR SERVER AUDIT CMCDB_SIT_Audit
    ADD (SELECT, UPDATE, INSERT, DELETE ON dbo.AppSetting BY dbo)
    WITH (STATE = ON)

select * from CMCDB_SIT.dbo.AppSetting

--Query the audit file
USE master
GO
SELECT * FROM   sys.fn_get_audit_file('E:\MSSQL\AUDIT\CMCDB*.sqlaudit',DEFAULT,DEFAULT )
GO

--drop action group from the Server Audit Specification
ALTER SERVER AUDIT SPECIFICATION CMCDB_SIT_Audit_Spec
FOR SERVER AUDIT CMCDB_SIT_Audit
  DROP (SUCCESSFUL_LOGIN_GROUP)
GO