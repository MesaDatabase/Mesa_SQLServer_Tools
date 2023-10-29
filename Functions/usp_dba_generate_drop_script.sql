
/****** Object:  StoredProcedure [dbo].[usp_dba_generate_drop_script]    Script Date: 10/7/2015 12:41:22 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[usp_dba_generate_drop_script] 

as


set nocount on

declare @dbname varchar(50)
declare @sql varchar (8000)
declare @pseudo varchar(20)
declare @mirror varchar(20)

declare @t1 table (DatabaseName varchar(100))
declare @t3 table (ClusterPseudo varchar(20), MirrorInstance varchar(20), DbName varchar(100))
declare @t4 table (ClusterPseudo varchar(20), MirrorInstance varchar(20))


insert into @t1
select name from master.dbo.sysdatabases as s1
  join DBA.dbo.tbl_tax_cluster_info as t1 on t1.SQLInstance = @@servername
  join DBA.dbo.tbl_tax_mirror_dbs as t2 on t1.ClusterPseudo = t2.ClusterPseudo and s1.name = t2.DbName
where t2.DropOnK = 1

insert into @t3
select c1.ClusterPseudo, c2.SQLInstance, DatabaseName
from @t1 as t1
  join DBA.dbo.tbl_tax_cluster_info as c1 on @@SERVERNAME = c1.SQLInstance and c1.Site = 'C'
  join DBA.dbo.tbl_tax_cluster_info as c2 on c1.ClusterPseudo = c2.ClusterPseudo and c2.Site = 'K'


insert into @t4
select distinct ClusterPseudo, MirrorInstance from @t3 as t3

while exists (select top 1 * from @t4 as t4)
begin
  select top 1 @pseudo = ClusterPseudo, @mirror = MirrorInstance from @t4 as t4
  set @sql = ''
  print @sql
  set @sql='--' + @pseudo
  print @sql
  set @sql = '--Run on ' + @mirror
  print @sql
  
  while exists (select top 1 * from @t3 as t3 where ClusterPseudo = @pseudo)
  begin
    select top 1 @dbname = DbName
    from @t3 as t3
    where ClusterPseudo = @pseudo
    order by DbName

    set @sql = '--' + @dbname
    print @sql
	set @sql = 
'EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = [' + @dbname + ']
GO
USE [master]
GO
ALTER DATABASE [' + @dbname + '] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE [' + @dbname + ']
GO'
	print(@sql)
	
	delete from @t3 where ClusterPseudo = @pseudo and DbName = @dbname
  end
  
  delete from @t4 where ClusterPseudo = @pseudo
end






GO