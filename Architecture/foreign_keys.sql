ALTER TABLE Person.ContactBackup
ADD CONSTRAINT FK_ContactBacup_Contact FOREIGN KEY (ContactID)
    REFERENCES Person.Person (BusinessEntityID) ;


Alter Table SalesOrderdetail nocheck constraint FTCustomerID;
Alter table SalesOrderdetail check constraint FTCustomerID;

select name,is_not_trusted from sys.foreign_keys where name= 'FTCustomerID'

Alter table SalesOrderdetail WITH CHECK check constraint FTCustomerID;
