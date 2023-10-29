--check common configurations
declare @temp table (ConfigId int, DesiredValue int, Comment varchar(500))
insert into @temp
values 
(101,0,'Should be set to the default of 0 (fast recovery).'),
(103,NULL,'Should be set to a fixed number. The default of 0 allows unlimited connections.'),
(106,NULL,'Set number of locks to a number such that the application code does not run out of locks; 10,000–50,000 locks are common'),
(109,NULL,'May be set higher to allow for index updates and less frequent index rebuilds.'),
(503,0,'Zero auto-configures the number of max worker threads depending on the number of processors, using the formula (256+(<processors> -4) * 8) for 32-bit SQL Server and twice that for 64-bit SQL Server.'),
(505,4096,'Set network packet size to match the packet size of network interface card and/or OS for optimal network throughput.  If you plan to implement bulk copy operations, a larger packet size will increase performance resulting in fewer network reads and writes.  The default is 4096.'),
(1539,0,'Limits number of threads during parallel query execution; values greater than the number of CPUs are ignored; the default 0 will use all available CPUs, while 1 disables parallelism.'),
(1544,NULL,'Total server memory minus 4GB');

select configuration_id, name, minimum, maximum, value_in_use, temp.DesiredValue, temp.Comment
from sys.configurations cf
  join @temp temp on cf.configuration_id = temp.ConfigId

