--move tempdb to its own drive
use tempdb
go

sp_helpfile

use master
go

alter database tempdb modify file (name = tempdata, filename = 'T:\MSSQL\Data\tempdb.mdf')
go

alter database tempdb modify file (name = templog, filename = 'S:\MSSQL\Tlog\tempdb.ldf')
go

--restart sql service and delete original tempdb files