set nocount off;
go
 
declare @tblHOBT TABLE
(
      [id]          int not null identity(1,1)
    , [dbid]        int not null
    , [database]    sysname not null
    , [schema]      sysname not null
    , [object]      sysname not null
    , [objectType] sysname not null
    , [index]       sysname null
    , [hobtID]      sysname not null
 
)
 
insert into @tblHOBT
(
      [dbid]
    , [database]
    , [schema]
    , [object]
    , [objectType]
    , [index]
    , [hobtID]
)
EXECUTE master.sys.sp_MSforeachdb 
    '
        if databasepropertyex(''?'', ''Collation'') is not null
        begin
 
            USE [?]; 
            select distinct
                      db_id()
                    , ''?''
                    , tblSS.[name]
                    , tblSO.[name]
                    , tblSO.[type_desc]
                    , tblSI.[name]
                    , tblSP.[hobt_id]
 
            from   sys.objects tblSO
 
            inner join sys.schemas tblSS
 
                on tblSO.schema_id = tblSS.schema_id
 
            inner join sys.indexes tblSI
 
                on tblSO.object_id = tblSI.object_id
 
            inner join sys.partitions tblSP
 
                on  tblSI.object_id = tblSP.object_id
                and tblSI.index_id = tblSP.index_id
 
            -- On User Table
            where tblSO.[type] = ''U'' 
 
 
        end
 
    '
 
select
        [rowNumber]
            = ROW_NUMBER() 
            OVER
                (
                    ORDER BY
                          [database] ASC
                        , [schema]   ASC
                        , [object]   ASC
                        , [index]    ASC
                ) 
 
        , [database] 
        , [schema]   
        , [object] 
        , [objectType]        
        , [index]   
        , [count]
            = count(*)
        , [aggregatedRecordLengthInBytes]
            = sum
            (
                aggregated_record_length_in_bytes
            )
        , [aggregatedRecordLengthInKB]
            = sum
            (
                aggregated_record_length_in_bytes
            )
            / (1024)
 
from   @tblHOBT tblHOBT
 
inner join sys.dm_tran_top_version_generators AS tblSTTVG
 
        on tblHOBT.[dbid] = tblSTTVG.database_id
        and tblHOBT.[hobtID] = tblSTTVG.rowset_id
 
group by
          [database] 
        , [schema]   
        , [object]   
        , [objectType] 
        , [index]   
 
order by
          [database] asc
        , [schema]   asc
        , [object]   asc
        , [index]    asc

SELECT * FROM sys.dm_tran_top_version_generators
select * from sys.databases order by database_id

SELECT SCHEMA_NAME(o.schema_id) AS SchemaName, o.name AS TableName 
FROM sys.partitions p
INNER JOIN sys.objects o
ON o.object_id = p.object_id
WHERE hobt_id = 72057594083999744