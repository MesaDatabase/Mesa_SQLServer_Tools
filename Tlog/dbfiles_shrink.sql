use DB1;
go

select * from sys.database_files
where type = 1

dbcc sqlperf(logspace)

dbcc loginfo(InventoryUS4);

dbcc shrinkfile(2);
go

alter database DB1
modify file (name = 'DB1_log', size = 45000)

