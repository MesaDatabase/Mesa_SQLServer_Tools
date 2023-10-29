
--command
DBCC CHECKDB ([NetPerfMon]) WITH NO_INFOMSGS, ALL_ERRORMSGS, DATA_PURITY

--errors
/*
Msg 8961, Level 16, State 1, Server A-PR-SQL-SLW-02, Line 1
Table error: Object ID 113818929, index ID 1, partition ID 72057742854848512, alloc unit ID 72057737019523072 (type LOB data). The off-row data node at page (1:1089), slot 0, text ID 819068408758272 does not match its reference from page (1:4204063), slot 0.
*/


--turn trace of
DBCC TRACEON (3604)

--check page contents
DBCC PAGE ( 'NetPerfMon', 1, 1089, 3)

--check table
select * from APM_ApplicationTemplate

--is physical or data inconsistency issue
dbcc checktable ('APM_ApplicationTemplate') with physical_only
dbcc checktable ('APM_ApplicationTemplate') with data_purity

--make a copy of the table and insert data from old to new
set identity_insert [APM_ApplicationTemplate_backup] on

insert into [APM_ApplicationTemplate_backup] (Id, Name, IsMockTemplate, Description, Created, LastModified, ViewId, ViewXml, UniqueId, Version, CustomApplicationType)
select Id, Name, IsMockTemplate, Description, Created, LastModified, ViewId, ViewXml, UniqueId, Version, CustomApplicationType
from APM_ApplicationTemplate

--check table
dbcc checktable ('APM_ApplicationTemplate_backup') with data_purity


--reference
--https://blog.angrydev.net/how-to-fix-dbcc-checkdb-inconsistency-errors-in-ms-sql-server-caused-by-upgrading-from-ntext-to-nvarcharmax/