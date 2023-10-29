USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[usp_dba_CopyPerflogs_2005]    Script Date: 10/7/2015 12:41:22 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





create procedure [dbo].[usp_dba_CopyPerflogs_2014] 

as

set nocount on

--declare and set variables
declare @sqlVer int
declare @node varchar(20)
declare @nodeIP varchar(20)
declare @perfPath varchar(500)
declare @perfFolder varchar(100)
declare @perfFolderPath varchar(500)
declare @perfFilePath varchar(500)
declare @perfFile varchar(500)
declare @csvPath varchar(500)
declare @sql varchar(500)
declare @csvName varchar(500)

declare @t1 table (Node varchar(20))
declare @t2 table (LogFile varchar(200))
declare @t3 table (NodeName varchar(20), LogFilePath varchar(500), LogFile varchar(200))
declare @t6 table (NodeName varchar(20), CsvFilePath varchar(500))
declare @t7 table (RelogOutput varchar(2000))

select @sqlVer = SQLVersion
from DBA.dbo.tbl_tax_cluster_info
where SQLInstance = @@servername


--get cluster node names
insert into @t1
select t2.NodeName
from DBA.dbo.tbl_tax_cluster_info as t1
  join DBA.dbo.tbl_tax_cluster_nodes as t2 on t1.ClusterPseudo = t2.ClusterPseudo and t1.Site = t2.Site
where SQLInstance = @@servername


--get directory paths for perfmon log folders
while exists (select top 1 Node from @t1 t1)
begin
  set @node = (select top 1 Node from @t1 t1)
  set @nodeIP = (select NodeIP from DBA.dbo.tbl_tax_cluster_nodes where NodeName = @node) 
	
  if @sqlVer = 2005
  begin
    set @perfPath = '\\' + @nodeIP + '\c$\perflogs'
  end
  if @sqlVer = 2008
  begin
    set @perfPath = '\\' + @nodeIP + '\c$\PerfLogs\Admin\' + @node
  end
  
  set @sql = 'exec xp_cmdshell ''dir /b ' + @perfPath + '\'''
  insert into @t2 exec(@sql)

  insert into @t3
  select @node, @perfPath, LogFile
  from @t2 t2
  where isnull(LogFile,'') like '%.blg'
  
  delete from @t1 where Node = @node
  delete from @t2
end
  

--run relog command on perfmon log files
while exists (select top 1 * from @t3 t3)
begin
  set @perfFile = (select top 1 LogFile from @t3 t3)
  set @perfFilePath = (select top 1 LogFilePath from @t3 t3 where LogFile = @perfFile)
  set @node = (select NodeName from @t3 t3 where LogFile = @perfFile)
  set @csvName = (select replace(LogFile,'.blg','') from @t3 t3 where LogFile = @perfFile)
  set @sql = 'exec xp_cmdshell ''relog ' + @perfFilePath + '\' + @perfFile + ' -f CSV -o ' + @perfPath + '\' + @csvName + '.csv'''
  --print(@sql)
  insert into @t7 exec(@sql)
  
  insert into @t6
  select @node, @perfPath + '\' + @csvName + '.csv'
  from @t3 t3
  
  delete from @t3 where LogFile = @perfFile
end
  

--copy to central location
while exists (select top 1 * from @t6 t6)
begin
  set @perfFilePath = (select top 1 CsvFilePath from @t6 t6)
  set @sql = 'exec xp_cmdshell ''xcopy ' + @perfFilePath + ' \\WKTAAPRODDBBP01\d$\TaxPerflog /Y'''
  --print(@sql)
  exec(@sql)
  delete from @t6 where CsvFilePath = @perfFilePath
end
  




GO