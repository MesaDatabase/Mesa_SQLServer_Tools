select 
replace(replace(filename,'E:\MSSQL\Data',''),'F:\MSSQL\Data',''),
'ren ' + filename + ' ' + replace(replace(filename,'E:\MSSQL\Data',''),'F:\MSSQL\Data',''),
'alter database [' + db_name(dbid) + '] modify file (name = ''' + name + ''', filename = ''' + replace(filename,'MSSQL\Data','MSSQL\Data\') + ''');'
--select *
from sys.sysaltfiles
where dbid > 4
  and dbid <> 32767
  and filename not like '%MSSQL\Data\%'