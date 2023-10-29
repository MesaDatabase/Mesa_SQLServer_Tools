--enable backup checksums when using maintenance plan for backup

--is 3023 enabled globally?
DBCC TRACESTATUS(3023) 

--enable globally or update startup option
DBCC TRACEON (3023,-1)

--check HasBackupChecksums column for recent backup
RESTORE HEADERONLY FROM DISK='L:\Backups\DB1\DB1_PROD_backup_date.bak'

--validate backup (restore on local machine)
RESTORE DATABASE CMCDB_BAK 
FROM DISK='C:\Users\user1\Desktop\DB1\PROD_backup_date.bak'
WITH 
MOVE 'CMCDB_PROD' TO 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\CMCDB_PROD_Primary.mdf',
MOVE 'CMCDB_PROD_data2' TO 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\CMCDB_PROD_Primary_2.ndf',
MOVE 'CMCDB_PROD_data3' TO 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\CMCDB_PROD_Primary_3.ndf',
MOVE 'CMCDB_PROD_data4' TO 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\CMCDB_PROD_Primary_4.ndf',
MOVE 'CMCDB_PROD_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\CMCDB_PROD_Primary.ldf',
CHECKSUM, RECOVERY

DBCC CHECKDB (CMCDB_BAK)