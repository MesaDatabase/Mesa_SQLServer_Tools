declare @sql varchar(500)
declare @t1 table (Output varchar(1000))

set @sql = 'exec xp_cmdshell ''wmic logicaldisk get name,volumename,size /format:csv'''
insert into @t1
exec(@sql)

select * from @t1 as t1
where Output like '%:%'