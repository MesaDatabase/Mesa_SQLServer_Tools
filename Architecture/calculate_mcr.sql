--drop tables
--drop table mcr_heap
--drop table mcr_clus
--drop table tmpInt

--create tables
create table mcr_heap (col1 bigint, col2 bigint, col3 varchar(255))
create table mcr_clus (id int identity(1,1), col1 bigint, col2 bigint, col3 varchar(255))
create clustered index CLIX_mrc_clus on dbo.mcr_clus (id)
create table tmpInt (IntVal int)

--create tmpChar with id 1-117 and another column of strings
select FileListID, ExtractTableName
into tmpChar
from DB.dbo.tblFileList
where Prefix = 'EXTRACT'
  and FileListID <= 117

--populate int table
declare @i int
set @i = 1

while @i <= 1414 --square root of how many rows you want
begin
  insert into tmpInt (IntVal)
  select @i

  set @i = @i + 1
end

--populate heap table
insert into mcr_heap (col1)
select i1.IntVal * i2.IntVal
from tmpInt as i1
cross join tmpInt as i2

update mcr_heap
set col2 = FLOOR(RAND()*((col1*5)-1+1))+1

update m1
set col3 = c.ExtractTableName
from mcr_heap as m1
  join tmpChar as c on m1.col2 % 117 = c.FileListID


--populate clustered table
insert into mcr_clus (col1)
select i1.IntVal * i2.IntVal
from tmpInt as i1
cross join tmpInt as i2

update mcr_clus
set col2 = FLOOR(RAND()*((col1*5)-1+1))+1

update m1
set col3 = c.ExtractTableName
from mcr_clus as m1
  join tmpChar as c on m1.col2 % 117 = c.FileListID

--validate data
select top 100 * from mcr_heap
select top 100 * from mcr_clus

--get statistics
set statistics io on
set statistics time on

Select sum(col2) from mcr_heap where col1 % 3 = 1 group by col3 option (maxdop 1)
Select sum(col2) from mcr_clus where col1 % 3 = 1 group by col3 option (maxdop 1)

/*
Steps to Calculate MCR:
	1-Get average logical reads: add logical reads from both queries and divide by 2
	2-Get average cpu time in seconds: add cpu time from both queries and divide by 2, then divide by 1000 to convert to seconds
	3-Get pages/sec: Avg logical reads / Avg cpu time in seconds
	4-Convert to Mb/sec: Pages/sec * 8/1024

Use MCR to calculate required cores:
	1-((Avg query size in Mb / MCR) * Concurrent users) / Target response time = Required # of cores

*/