OPEN MASTER KEY DECRYPTION BY PASSWORD
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY



use master
go
select * from sys.symmetric_keys
select * from sys.asymmetric_keys
select * from sys.key_encryptions

select name from sys.databases
where is_master_key_encrypted_by_server = 1

use testEncrypt
go
select * from sys.symmetric_keys
select * from sys.asymmetric_keys
select * from sys.key_encryptions


USE testEncrypt  
GO  
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'n"4/P6p2"Wi%.=w'  
GO  

USE testEncrypt  
GO  
ALTER MASTER KEY DROP ENCRYPTION BY SERVICE MASTER KEY
GO  

USE testEncrypt  
GO  
OPEN MASTER KEY DECRYPTION BY PASSWORD = 'n"4/P6p2"Wi%.=w'  
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY
GO 



create table dbo.test_hash (TestId int, pwd varbinary(128))

OPEN MASTER KEY DECRYPTION BY PASSWORD = 'n"4/P6p2"Wi%.=w' 

CREATE CERTIFICATE test_cert
WITH SUBJECT = 'Test Password';
GO 

CREATE SYMMETRIC KEY test_key
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE test_cert;
GO 

OPEN SYMMETRIC KEY test_key DECRYPTION BY CERTIFICATE test_cert;

insert into test_hash (TestId) select 1
insert into test_hash (TestId) select 2

update test_hash
set pwd = ENCRYPTBYKEY(Key_GUID('test_key'),N'mypassword')
where TestId = 2

select * from test_hash

select ENCRYPTBYKEY(Key_GUID('test_key'),N'mypassword')
select ENCRYPTBYKEY(Key_GUID('test_key'),N'mypassword')
select ENCRYPTBYKEY(Key_GUID('test_key'),N'mypassword')


/*
question: in order to restore the encrypted db on another instance, 
do i need to backup/restore the key 
or can i just open with decryption by password 
and add encryption with service master key
*/

backup database testEncrypt to disk = 'O:\SERVER3_testEncrypt_2017041415361.bak'

