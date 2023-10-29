--Check for login failures
declare @temp table (LogDate datetime, ProcessInfo char(8), Text varchar(max))
insert into @temp
exec master.dbo.xp_readerrorlog 0, 1, N'Login fail', NULL, NULL, NULL, N'desc' 

select * from @temp t1
where 1=1
  and LogDate >= GETDATE() - 1 --last day
  --and LogDate >= GETDATE() - .0013888 --last 2 minutes
