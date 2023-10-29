begin transaction DeleteAccountWarning98
with mark 'DELETE Account Warning 98';
go

delete
from AccountWarning
where WarningCodes = '098';
go

commit transaction DeleteAccountWarning98;
go



-- Time passes. Regular database   
-- and log backups are taken.  
-- An error occurs in the database.  
USE master  
GO  

RESTORE DATABASE mydb
FROM backup_file
with norecovery;

RESTORE LOG mydb
   FROM log_backup_file
with norecovery,   
   STOPATMARK = 'DeleteAccountWarning98'; 

