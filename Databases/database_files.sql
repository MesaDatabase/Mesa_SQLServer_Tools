select 
  @@SERVERNAME as ServerName,
  dbid as DbId,
  DB_NAME(dbid) as DbName,
  case when filename like '%.mdf%' or filename like '%.ndf%' then 'Data' else 'Log' end as FileType,
  size,
  growth,
  fileid,
  name,
  LEFT(filename,1) as Drive
from master.dbo.sysaltfiles
where dbid != 32767
  and DB_NAME(dbid) not in ('DBA')
order by 2,4,7