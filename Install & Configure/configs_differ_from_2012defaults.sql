--find where configurations are different than default
declare @temp table (ConfigId int, [2008R2_Default] int, [2012_Default] int)
insert into @temp
values (101,0,0),
(102,0,0),
(103,0,0),
(106,0,0),
(107,0,0),
(109,0,0),
(114,0,0),
(115,1,1),
(116,1,1),
(117,1,1),
(124,0,0),
(400,0,0),
(503,0,0),
(505,4096,4096),
(518,0,0),
(542,0,0),
(544,0,0),
(1126,1033,1033),
(1127,2049,2049),
(1505,0,0),
(1517,0,0),
(1519,20,10),
(1520,600,600),
(1531,-1,-1),
(1532,0,0),
(1534,0,0),
(1535,0,0),
(1536,65536,65536),
(1537,0,0),
(1538,5,5),
(1539,0,0),
(1540,1024,1024),
(1541,-1,-1),
(1543,0,0),
(1544,2147483647,2147483647),
(1545,0,0),
(1546,0,0),
(1547,0,0),
(1548,0,0),
(1549,0,0),
(1550,0,0),
(1551,0,0),
(1555,0,0),
(1556,0,0),
(1557,60,60),
(1562,0,0),
(1563,4,4),
(1564,0,0),
(1565,100,100),
(1566,0,0),
(1567,100,100),
(1568,1,1),
(1569,0,0),
(1570,0,0),
(1576,0,0),
(1577,0,0),
(1578,0,0),
(1579,0,0),
(1580,0,0),
(1581,0,0),
(1582,0,0),
(1583,0,0),
(16384,0,0),
(16385,0,NULL),
(16386,0,0),
(16387,1,1),
(16388,0,0),
(16390,0,0),
(16391,0,0),
(16392,0,0);


select configuration_id, name, minimum, maximum, value_in_use, temp.[2012_Default]
from sys.configurations cf
  join @temp temp on cf.configuration_id = temp.ConfigId
where @@version like '%2012%'
  and cf.value_in_use <> temp.[2012_Default]

union

select configuration_id, name, minimum, maximum, value_in_use, temp.[2008R2_Default]
from sys.configurations cf
  join @temp temp on cf.configuration_id = temp.ConfigId
where @@version like '%2008%'
  and cf.value_in_use <> temp.[2008R2_Default]
  

