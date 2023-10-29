--view auto page repair attempts for AlwaysOn
select * from sys.dm_hadr_auto_page_repair

--view auto page repair attempts for DB Mirroring
select * from sys.dm_db_mirroring_auto_page_repair

--see status of pages marked suspect
select * from msdb.dbo.suspect_pages

