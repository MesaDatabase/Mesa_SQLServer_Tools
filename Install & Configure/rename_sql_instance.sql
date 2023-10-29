/***********************************************************
-- Description  : Rename SQL instance (internal)
-- Created Date : 20190325
-- Created By   : Renee Jaramillo
-- Notes		: 
-- Modified		: 
***********************************************************/


----------default instance
select @@servername;

exec sp_dropserver 'A-DV-ENG-SB-01' 
GO  
exec sp_addserver 'A-DV-ENG-SB-03', local;  
GO

--restart sql services


----------named instance
select @@servername;

exec sp_dropserver 'A-DV-ENG-SB-01\named' 
GO  
exec sp_addserver 'A-DV-ENG-SB-03\named', local;  
GO