select * FROM sys.databases
select * FROM sys.database_role_members
select * from sys.database_principals
select * from sys.database_permissions
select * from sys.syspermissions

--db principal role members
SELECT DP1.name AS DatabaseRoleName,   
   isnull (DP2.name, 'No members') AS DatabaseUserName   
 FROM sys.database_role_members AS DRM  
 RIGHT OUTER JOIN sys.database_principals AS DP1  
   ON DRM.role_principal_id = DP1.principal_id  
 LEFT OUTER JOIN sys.database_principals AS DP2  
   ON DRM.member_principal_id = DP2.principal_id  
WHERE DP1.type = 'R'
ORDER BY DP1.name;  


--db permissions on which objects and to whom
SELECT per.*, dp.name, o.name
FROM sys.database_permissions AS per  
	JOIN sys.database_principals AS dp ON per.grantee_principal_id = dp.principal_id  
	LEFT JOIN sys.objects AS o ON per.major_id = o.object_id
where 1=1
  and dp.name = 'AzureDFReadOnly'