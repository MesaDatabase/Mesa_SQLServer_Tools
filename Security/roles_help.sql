exec [sys].[sp_helpsrvrole]
exec [sys].[sp_srvrolepermission]
select * from sys.server_permissions

exec [sys].[sp_helpsrvrolemember]

exec [sys].[sp_helpdbfixedrole]
exec [sys].[sp_dbfixedrolepermission]
select * from sys.database_permissions

exec [sys].[sp_helprolemember]
