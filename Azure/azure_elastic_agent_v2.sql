--connect to job db
-- Create a database scoped credential.  
CREATE DATABASE SCOPED CREDENTIAL jobcred WITH IDENTITY = 'jobcred',
    SECRET = 'secret'; 
GO

-- Create a database scoped credential for the master database of server1.
CREATE DATABASE SCOPED CREDENTIAL mastercred WITH IDENTITY = 'mastercred',
    SECRET = 'secret'; 
GO

--connect to master
CREATE LOGIN masteruser WITH PASSWORD = 'secret';
CREATE USER masteruser FROM LOGIN masteruser;
CREATE LOGIN jobuser WITH PASSWORD = 'secret';

--connect to user db
CREATE USER jobuser FROM LOGIN jobuser;


-------------target group
-- Connect to the job database specified when creating the job agent

-- Add a target group containing server(s)
EXEC jobs.sp_add_target_group 'NonProdGroup1'

-- Add a server target member
EXEC jobs.sp_add_target_group_member
'NonProdGroup1',
@target_type = 'SqlServer',
@refresh_credential_name='mastercred', --credential required to refresh the databases in server
@server_name='npduseamdapsqlsrv.database.windows.net'

--View the recently created target group and target group members
SELECT * FROM jobs.target_groups WHERE target_group_name='NonProdGroup1';
SELECT * FROM jobs.target_group_members WHERE target_group_name='NonProdGroup1';