http://blog.sqlauthority.com/2009/04/28/sql-server-introduction-to-sql-server-encryption-and-symmetric-key-encryption-tutorial-with-script/
/* Symmetric Key:
	In Symmetric cryptography system, the sender and the receiver of a message share a single, common key that is used to encrypt and decrypt the message. 
	This is relatively easy to implement, and both the sender and the receiver can encrypt or decrypt the messages. 

   Asymmetric Key:
	Asymmetric cryptography, also known as Public-key cryptography, is a system in which the sender and the receiver of a message have a pair of cryptographic keys – a public key and a private key – to encrypt and decrypt the message. 
	This is a relatively complex system where the sender can use his key to encrypt the message but he cannot decrypt it. 
	The receiver, on the other hand, can use his key to decrypt the message but he cannot encrypt it. 
	This intricacy has turned it into a resource-intensive process. 
*/

/* Certificates
	A public key certificate is a digitally signed statement that binds the value of a public key to the identity of the person, device, or service that holds the corresponding private key. 
	A Certification Authority (CA) issues and signs certifications
*/

/* Internal SQL Server Encryption
	Database Level
	  This level secures all the data in a database. 
	  However, every time data is written or read from database, the whole database needs to be decrypted. 
	  This is a very resource-intensive process and not a practical solution. 

	Column (or Row) Level
	  This level of encryption is the most preferred method. 
	  Here, only columns containing important data should be encrypted; this will result in lower CPU load compared with the whole database level encryption. 
	  If a column is used as a primary key or used in comparison clauses (WHERE clauses, JOIN conditions) the database will have to decrypt the whole column to perform operations involving those columns. 
*/

/* Service Master Key: 
	At the top of the key hierarchy is the Service Master Key. 
	There is one per SQL Server instance, it is a symmetric key, and it is stored in the master database. 
	Used to encrypt Database Master Keys, Linked Server passwords and Credentials it is generated at first SQL Server startup.
	There are no user configurable passwords associated with this key – it is encrypted by the SQL Server service account and the local machine key. 
	On startup SQL Server can open the Service Master Key with either of these decryptions. 
	If one of them fails – SQL Server will use the other one and ‘fix’ the failed decryption (if both fail – SQL Server will error). 
	This is to account for situations like clusters where the local machine key will be different after a failover. 
	This is also one reason why service accounts should be changed using SQL Server Configuration Manager – because then the Service Master Key encryption is regenerated correctly.
	Service Master Keys can be manually regenerated using this statement:
*/

--This will decrypt and re-encrypt all secrets encrypted with the key.
alter service master key regenerate

--The Service Master Key is backed up with the master database, but can be backed up and restored independently:
backup service master key to file = N'<filepath and filename>'
encryption by password = '<password>'
go

restore service master key from file = N'<filepath and filename>'
decryption by password = '<password>'
go

--The Service Master Key properties are available by running the following query in the master database:
use master
go
select * from sys.symmetric_keys

/* Database Master Key: 
	This is a database scoped symmetric key that is encrypted by the Service Master Key and stored in the database. 
	It can be used to encrypt certificates and/or asymmetric keys within the database. 
	Unlike the Service Master Key which is generated automatically, a Database Master Key must be created with DDL.
	There is one Database Master Key per database and it must be protected by a password. 
	The Database Master Key can be encrypted by multiple passwords and any of these can be used to de-crypt the key. 
	By default the Database Master Key is also encrypted by the Service Master Key, this can be switched off if needed.
*/

--Create database master key
use <database>
go
create master key encryption by password = '<password>'

--The Database Master Key can also be examined in the system catalog
use <database>
go
select * from sys.symmetric_keys

--Database Master Keys are backed up and restored with the database, but can also be backed up and restored independently
use <database>
go
backup master key to file = N'<filepath and filename>'
	encryption by password = '<file password>'

restore master key from file = N'<filepath and filename>'
	decryption by password = '<file password>'
	encryption by password = '<new encryption password>'
	

/* Migrating Databases: 
	If a database makes use of a Database Master Key, and that key is encrypted by the Service Master Key, then this encryption will need to be regenerated on the destination instance after any migration.
*/

--Firstly verify whether there are any Database Master Keys encrypted by the Service Master Key: 

select name from sys.databases
where is_master_key_encrypted_by_server = 1

--If you don’t know a valid password for the Database Master Key you can create a new one. (Remember that multiple passwords can encrypt the DMK) (optional) 
use <database>
go
alter master key 
add encryption by password = 'migration_password'
go

--Drop the encryption by the Service Master Key: 
use <database>
go
alter master key drop encryption by service master key
go

--Migrate the database using either backup and restore, or detach and attach. 
--https://mattsql.wordpress.com/2012/11/13/migrating-sql-server-databases-that-use-database-master-keys/
--Open the Database Master Key with a password (this could be the password created at step 2) and re-activate the encryption by Service Master Key – this will be mapped to the SMK on the new SQL instance:
use <database>
go
open master key decryption by password = '<Password>'
alter master key add encryption by service master key
go

--If you created a password specifically for the migration in step 2, then you should drop it:  (optional)
use <database>
go
alter master key 
drop encryption by password = 'migration_password'
go



