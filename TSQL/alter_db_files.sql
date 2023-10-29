use master

go

Alter database tempdb modify file (name = tempdb, filename = 'New_path:\tempdb.mdf')

go

Alter database tempdb modify file (name = templog, filename = 'New_path:\templog.ldf')

go

 

