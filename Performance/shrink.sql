--free space in files
DECLARE
      @SqlStatement nvarchar(MAX)
      ,@DatabaseName sysname;
      
--IF OBJECT_ID(N'tempdb..#DatabaseSpace') IS NOT NULL
--    DROP TABLE #DatabaseSpace;
      
CREATE TABLE #DatabaseSpace(
      DATABASE_NAME     sysname
      ,LOGICAL_NAME     sysname
      ,FILE_SIZE_MB     decimal(12, 2)
      ,SPACE_USED_MB    decimal(12, 2)
      ,FREE_SPACE_MB    decimal(12, 2)
    ,FILEID        int
      ,FILE_NAME        sysname
      );
      
DECLARE DatabaseList CURSOR LOCAL FAST_FORWARD FOR
      SELECT name FROM sys.databases where state_desc='ONLINE';
      
OPEN DatabaseList;
WHILE 1 = 1
BEGIN
      FETCH NEXT FROM DatabaseList INTO @DatabaseName;
      IF @@FETCH_STATUS = -1 BREAK;
      SET @SqlStatement = N'USE '
            + QUOTENAME(@DatabaseName)
            + CHAR(13)+ CHAR(10)
            + N'INSERT INTO #DatabaseSpace
      SELECT            
             [DATABASE_NAME] = DB_NAME()
            ,[LOGICAL_NAME] = f.name
            ,[FILE_SIZE_MB] = CONVERT(decimal(12,2),round(f.size/128.000,2))
            ,[SPACE_USED_MB] = CONVERT(decimal(12,2),round(fileproperty(f.name,''SpaceUsed'')/128.000,2))
            ,[FREE_SPACE_MB] = CONVERT(decimal(12,2),round((f.size-fileproperty(f.name,''SpaceUsed''))/128.000,2))
            ,[FILEID]= f.file_id
            ,[FILENAME] = f.physical_name
      FROM sys.database_files f;';

      EXECUTE(@SqlStatement);
      
END
CLOSE DatabaseList;
DEALLOCATE DatabaseList;

--change drive letter on '%S:\%' by drive you need release space
SELECT * FROM #DatabaseSpace where file_name like '%J:\%' and FILE_SIZE_MB>0 order by 5 desc ;

DROP TABLE #DatabaseSpace;
GO




-----------------------shrink

declare @fsize float, @spaceus float, @idfile int,@numfiles int,@increment int

set @increment =1 
select @numfiles=count(*) from sysfiles
--print @numfiles

while @increment<=@numfiles
begin

select
      @idfile=a.FILEID,
      @fsize= convert(decimal(12,2),round(a.size/128.000,2)),
      @spaceus= convert(decimal(12,2),round(fileproperty(a.name,'SpaceUsed')/128.000,2))
from
      dbo.sysfiles a where a.fileid=@increment
print @idfile
print @fsize
print @spaceus
declare @tamano int

select @tamano = @fsize
   while @tamano >@spaceus   
     begin
             dbcc shrinkfile(@idfile,@tamano) 
           select @tamano
           select @tamano = @tamano -200  
     end

  set @increment=@increment + 1
end
