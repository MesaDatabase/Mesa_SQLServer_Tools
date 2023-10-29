--on instance with original database
BACKUP SERVICE MASTER KEY TO FILE = 'c:\temp\ssidb_service_master_key' ENCRYPTION BY PASSWORD = 'u%58G#D9Ol&yh$M&%EB';

--on instance where db was restored
use master;

RESTORE SERVICE MASTER KEY
FROM FILE = '\\a-pr-sql-104\c$\temp\ssidb_service_master_key'
DECRYPTION BY PASSWORD = 'u%58G#D9Ol&yh$M&%EB'
FORCE


use ssisdb;

open master key decryption by PASSWORD = 'u%58G#D9Ol&yh$M&%EB'

alter master key add encryption by service master key