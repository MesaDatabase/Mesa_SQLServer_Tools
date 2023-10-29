--see if any pages are suspect
select * from msdb.dbo.suspect_pages

--see page repair attempts
select * from sys.dm_hadr_auto_page_repair 
select * from sys.dm_db_mirroring_auto_page_repair 