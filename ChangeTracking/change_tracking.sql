ALTER DATABASE AkcelerantPF  
SET CHANGE_TRACKING = ON  
(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON)  


ALTER TABLE Database.Application
ENABLE CHANGE_TRACKING  
WITH (TRACK_COLUMNS_UPDATED = OFF)  


SELECT * FROM CHANGETABLE (CHANGES Database.Application , NULL) AS c;  
 
select * from sys.objects
where name like '%change%'

select schema_name(o.schema_id), o.name,
	'SELECT count(1) FROM CHANGETABLE (CHANGES ' + schema_name(o.schema_id) + '.' + o.name + ', NULL) AS c;',
	'ALTER TABLE ' + schema_name(o.schema_id) + '.' + o.name + ' DISABLE CHANGE_TRACKING',
	'SELECT ''' + schema_name(o.schema_id) + ''',''' + o.name + ''', count(1) FROM CHANGETABLE (CHANGES ' + schema_name(o.schema_id) + '.' + o.name + ', NULL) AS c union',
	'SELECT ''' + schema_name(o.schema_id) + ''',''' + o.name + ''', count(1) FROM ' + schema_name(o.schema_id) + '.' + o.name + ' AS s (nolock) union',
	'GRANT VIEW CHANGE TRACKING ON ' + schema_name(o.schema_id) + '.'  + o.name + ' TO [AzureDFReadOnly]'
from sys.change_tracking_tables as c
  join sys.objects as o on c.object_id = o.object_id
order by 1,2



SELECT top 10 *
FROM Database.Application  AS e  
CROSS APPLY CHANGETABLE   
    (CHANGES Database.Application , NULL) AS c;  

SELECT top 10 *
FROM CHANGETABLE (CHANGES Database.Application , NULL) AS c  
    LEFT OUTER JOIN Database.Application  AS e  
        ON e.ApplicationId = c.ApplicationId


ALTER TABLE Database.Application 
DISABLE CHANGE_TRACKING  


ALTER DATABASE AkcelerantPF  
SET CHANGE_TRACKING = OFF



select * from sys.internal_tables
where OBJECT_NAME(parent_object_id) = 'Application'


exec sp_spaceused 'sys.change_tracking_1414308844'  
exec sp_spaceused 'sys.syscommittab'  




-- Get all changes (inserts, updates, deletes)  
DECLARE @last_sync_version bigint;  
--SET @last_sync_version = CHANGE_TRACKING_CURRENT_VERSION();  
SET @last_sync_version = 1

SELECT *
FROM CHANGETABLE (CHANGES Database.Application , @last_sync_version) AS c  
    LEFT OUTER JOIN Database.Application  AS e  
        ON e.Id = c.Id


--for applicant (test with column change tracking)
DECLARE @PCMColumnId int = COLUMNPROPERTY(  
    OBJECT_ID('Database.Applicant'),'PreferredContactMethodId', 'ColumnId')  
  
SELECT  
    *,
    CASE  
           WHEN CHANGE_TRACKING_IS_COLUMN_IN_MASK(  
                     @PCMColumnId, CT.SYS_CHANGE_COLUMNS) = 1  
            THEN PreferredContactMethodId  
            ELSE NULL  
      END AS CT_PreferredContactMethodId,  
      CHANGE_TRACKING_IS_COLUMN_IN_MASK(  
                     @PCMColumnId, CT.SYS_CHANGE_COLUMNS) AS  
                                   CT_PreferredContactMethodId_Changed,  
     CT.SYS_CHANGE_OPERATION, CT.SYS_CHANGE_COLUMNS,  
     CT.SYS_CHANGE_CONTEXT  
FROM  
     Database.Applicant AS P  
INNER JOIN  
     CHANGETABLE(CHANGES Database.Applicant, NULL) AS CT  
ON  
     P.ApplicantId = CT.ApplicantId AND  
     CT.SYS_CHANGE_OPERATION = 'U'  




----------------get tables to enable change tracking on

select *,
'ALTER TABLE ' + schema_name(schema_id) + '.' + name + ' ENABLE CHANGE_TRACKING WITH (TRACK_COLUMNS_UPDATED = OFF)'
from sys.objects
where schema_name(schema_id) + '.' + name in (


'Database.Asset'

)
  and schema_name(schema_id) + '.' + name not in (
select schema_name(o.schema_id) + '.' + o.name
from sys.change_tracking_tables as c
  join sys.objects as o on c.object_id = o.object_id
)
