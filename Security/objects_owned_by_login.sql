declare @Login as SYSNAME
set @Login = 'na\user'

    declare @sql varchar(MAX), @DB_Objects varchar(MAX)
    Select @DB_Objects = ' L.name COLLATE DATABASE_DEFAULT as Login, U.Name  COLLATE DATABASE_DEFAULT as [User]
	, o.name COLLATE DATABASE_DEFAULT as [name]
	, o.object_id
	, o.principal_id
	, o.schema_id
	, o.parent_object_id
	, o.type COLLATE DATABASE_DEFAULT as [type]
	, o.type_desc COLLATE DATABASE_DEFAULT as [type_desc]
	, o.create_date
	, o.modify_date
	, o.is_ms_shipped
	, o.is_published
	, o.is_schema_published
     From %D%.sys.objects o
      Join %D%.sys.database_principals u 
        ON Coalesce(o.principal_id
			 , (Select S.Principal_ID from %D%.sys.schemas S Where S.Schema_ID = O.schema_id))
            = U.principal_id
      Left Join %D%.sys.server_principals L on L.sid = u.sid
'

    Select @sql = 'SELECT * FROM
    (Select '+Cast(database_id as varchar(9))+' as DBID, ''master'' as DBName, '
                     + Replace(@DB_objects, '%D%', [name])
     From master.sys.databases
     Where [name] = 'master'

    Select @sql = @sql + 'UNION ALL Select '+Cast(database_id as varchar(9))+', '''+[name]+''', '
                     + Replace(@DB_objects, '%D%', [name])
     From master.sys.databases
     Where [name] != 'master' and [name] not like '%ag_test%'

    Select @sql = @sql + ') oo  Where Login = ''' + @Login + ''''

    print @sql
    EXEC (@sql)