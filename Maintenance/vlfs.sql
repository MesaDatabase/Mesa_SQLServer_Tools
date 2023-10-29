/*
Transaction logs can become *VERY* fragmented when they are not preallocated and instead they grow excessively through unmanaged (and probably the default settings for) auto-growth. 

While having WAY too many VLFs because of auto-growth is still the most common form of problem within transaction logs, another problem has been creeping up more and more… too few VLFs. 

If you preallocate a very large transaction log (10s to 100s of GB), SQL Server may only allocate a few VLFs – as a result, log backups will be allowed to run normally but, 
SQL Server only clears the inactive VLFs when you've moved into a different VLF. 

If your VLFs are 8GB in size, then you need to accumulate 8GB of log information before the log can be cleared…so, many of your log backups will occur normally but then one (the one that finally hits > 8GB in used size) 
will take quite a bit more time AND possibly cause you performance problems because it's now clearing 8GB of log information. 

First, here's how the log is divided into VLFs. Each "chunk" that is added, is divided into VLFs at the time the log growth (regardless of whether this is a manual or auto-grow addition) and it's all 
dependant on the size that is ADDED not the size of the log itself. 

So, take a 10MB log that is extended to 50MB, here a 40MB chunk is being added. This 40MB chunk will be divided into 4 VLFs. Here's the breakdown for chunksize: 

- chunks less than 64MB and up to 64MB = 4 VLFs 
- chunks larger than 64MB and up to 1GB = 8 VLFs 
- chunks larger than 1GB = 16 VLFs 

And, what this translates into is that a transaction log of 64GB would have 16 VLFs of 4GB each. As a result, the transaction log could only clear at more than 4GB of log information AND that only when it's completely inactive. 

To have a more ideally sized VLF, consider creating the transaction log in 8GB chunks (8GB, then extend it to 16GB, then extend it to 24GB and so forth) so that the number (and size) of your VLFs is more reasonable (in this case 512MB). 



grow a log file in increments of 8GB to keep the VLF size at 512MB (a growth of 1GB or more create 16VLFs, with each VLF being 1/16th the size of the growth). 

.0625G (64MB) chunk = 4VLFs (each VLF is 16MB)
1G chunk = 8VLFs (each VLF is 128MB)
8GB chunk = 16VLFs (each VLF is 512MB)


--file size < 1GB
vlf count = file size GB * 64

--file size >= 1GB and < 8GB
vlf count = file size GB * 8

--file size >= 8GB
vlf count = file size GB * 2

db created 1MB log file = 4 vlfs
db created 64MB log file = 4 vlfs
db created 1GB log file = 8 vlfs
db created 4GB log file = 16 vlfs
db created 6GB log file = 16 vlfs
db created 8GB log file = 16 vlfs

*/

--query
--variables to hold each 'iteration' 
declare @query varchar(100) 
declare @dbname sysname 
declare @vlfs int 
  
--table variable used to 'loop' over databases 
declare @databases table (dbname sysname) 
insert into @databases 
--only choose online databases 
select name from sys.databases 
where state = 0 
  and name not in ('master','model','msdb','DBA','DellDBA','DellDBAUtility','PSDBA')
  
--table variable to hold results 
declare @vlfcounts table 
    (dbname sysname, 
    vlfcount int) 
  
 
 
--table variable to capture DBCC loginfo output 
--changes in the output of DBCC loginfo from SQL2012 mean we have to determine the version 
 
declare @MajorVersion tinyint 
set @MajorVersion = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)))-1) 
 
if @MajorVersion < 11 -- pre-SQL2012 
begin 
    declare @dbccloginfo table 
    ( 
        fileid tinyint, 
        file_size bigint, 
        start_offset bigint, 
        fseqno int, 
        [status] tinyint, 
        parity tinyint, 
        create_lsn numeric(25,0) 
    ) 
  
    while exists(select top 1 dbname from @databases) 
    begin 
  
        set @dbname = (select top 1 dbname from @databases) 
        set @query = 'dbcc loginfo (' + '''' + @dbname + ''') ' 
  
        insert into @dbccloginfo 
        exec (@query) 
  
        set @vlfs = @@rowcount 
  
        insert @vlfcounts 
        values(@dbname, @vlfs) 
  
        delete from @databases where dbname = @dbname 
  
    end --while 
end 
else 
begin 
    declare @dbccloginfo2012 table 
    ( 
        RecoveryUnitId int, 
        fileid tinyint, 
        file_size bigint, 
        start_offset bigint, 
        fseqno int, 
        [status] tinyint, 
        parity tinyint, 
        create_lsn numeric(25,0) 
    ) 
  
    while exists(select top 1 dbname from @databases) 
    begin 
  
        set @dbname = (select top 1 dbname from @databases) 
        set @query = 'dbcc loginfo (' + '''' + @dbname + ''') ' 
  
        insert into @dbccloginfo2012 
        exec (@query) 
  
        set @vlfs = @@rowcount 
  
        insert @vlfcounts 
        values(@dbname, @vlfs) 
  
        delete from @databases where dbname = @dbname 
  
    end --while 
end 

declare @t1 table (DatabaseName varchar(100))
insert into @t1
select name from master.dbo.sysdatabases 

create table #t2 (DatabaseName varchar(100), file_id int, file_name varchar(100), physical_name varchar(200), type varchar(10), drive char(1), 
				  growth int, isPercentGrowth bit, sizeMB decimal(17,4), space_usedMB decimal(17,4), sizeGB decimal(17,4), space_usedGB decimal(17,4))

declare @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
--USE master;
EXEC(N'USE [' + @dbname + N']; EXEC(''insert into #t2 select db_name(), file_id, name, physical_name, type_desc, left(physical_name,1),
growth, is_percent_growth,
size/128.0 as SizeMB,
CAST(FILEPROPERTY(name, ''''SpaceUsed'''') AS int)/128.0 as SpaceUsedMB,
size/128.0/1024 as SizeGB,
CAST(FILEPROPERTY(name, ''''SpaceUsed'''') AS int)/128.0/1024 as SpaceUsedGB
FROM sys.database_files;'');');
delete from @t1 where DatabaseName = @dbname
end 

select 
  @@servername, dbname, vlfcount, t2.file_name, t2.physical_name, 
  t2.sizeMB, t2.space_usedMB, t2.sizeGB, t2.space_usedGB,
  case when t2.isPercentGrowth = 0 then t2.growth/128 else t2.growth end as growthMB,
  t2.isPercentGrowth,
  case when sizeGB < 1 then
	   case when vlfcount <= 4 then 'Good VLF Count'
		    when vlfcount >= sizeGB * 64 then 'Too Many VLFS'
		   else 'Good VLF Count' end
  when sizeGB >= 1 and sizeGB < 8 then
		case when vlfcount >= sizeGB * 8 then 'Too Many VLFS'
		   else 'Good VLF Count' end	   
  when sizeGB >= 8 then
		case when vlfcount >= sizeGB * 2 then 'Too Many VLFS'
		   else 'Good VLF Count' end	   
  end as VlfStatus,
  case when sizeGB < 1 then 4
	   when sizeGB >= 1 and sizeGB < 8 then cast(sizeGB*8 As int)	   
	   when sizeGB >= 8 then cast(sizeGB*2 As int)
  end as IdealVLFCount,
  case when sizeGB < 1 then '64MB'
	   when sizeGB >= 1 and sizeGB < 8 then '1GB'	   
	   when sizeGB >= 8 then '8GB'
  end as GrowthChunk  
from @vlfcounts as v1
  join #t2 as t2 on v1.dbname = t2.DatabaseName
where type = 'LOG'
order by dbname

drop table #t2
