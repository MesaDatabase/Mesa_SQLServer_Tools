go
sp_helpfile
go

use master
go
sp_detach_db 'ECC'
go

use master
go
sp_attach_db 'ECC','T:\ECC_Prod_Data.MDF','S:\ECC_Prod_Log.LDF'
go