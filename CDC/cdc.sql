/*
https://www.simple-talk.com/sql/learn-sql-server/introduction-to-change-data-capture-%28cdc%29-in-sql-server-2008/
*/

--is cdc enabled
USE master 
GO 
SELECT [name], database_id, is_cdc_enabled  
FROM sys.databases       
GO    


--enable database for cdc (creates cdc schema in the db)
USE AdventureWorks 
GO 
EXEC sys.sp_cdc_enable_db 
GO 


--system tables that get created
cdc.captured_columns – This table returns result for list of captured column. 
cdc.change_tables – This table returns list of all the tables which are enabled for capture. 
cdc.ddl_history – This table contains history of all the DDL changes since capture data enabled. 
cdc.index_columns – This table contains indexes associated with change table. 
cdc.lsn_time_mapping – This table maps LSN number (for which we will learn later) and time. 


--is cdc enabled for tables
USE AdventureWorks 
GO 
SELECT [name], is_tracked_by_cdc  
FROM sys.tables 
GO  



/*
--when cdc is enabled on a table, two CDC-related jobs are created

Additionally, it is very important to understand the role of the required parameter @role_name. If there is any restriction of how data should be extracted from database, this option is used to specify any role which is following restrictions and gating access to data to this option if there is one.  If you do not specify any role and, instead, pass a NULL value, data access to this changed table will not be tracked and will be available to access by everybody. 

By default, all the columns of the specified table  are taken into consideration when using sys.sp_cdc_enable_table . If you want to only few columns of this table to be tracked in that case you can specify the columns as one of the parameters of above mentioned SP. 

*/


--enable cdc on a table
USE AdventureWorks 
GO 
EXEC sys.sp_cdc_enable_table 
@source_schema = N'HumanResources', 
@source_name   = N'Shift', 
@role_name     = NULL 
GO



/*

When everything is successfully completed,  check  the system tables again and you will find a new table  called cdc.HumanResources_Shift_CT. This table will contain all the changes in the table HumanResources.Shift. If you expand this table, you will find five additional columns as well.  

As you will see there are five additional columnsto the mirrored original table

__$start_lsn 
__$end_lsn 
__$seqval 
__$operation 
__$update_mask
There are two values which are very important to us is __$operation and __$update_mask. 

Column _$operation contains value which corresponds to DML Operations. Following is quick list of value and its corresponding meaning.

Delete Statement = 1 

Insert Statement = 2 

Value before Update Statement = 3 

Value after Update Statement = 4 

The column _$update_mask shows, via a bitmap,   which columns were updated in the DML operation that was specified by _$operation.  If this was  a DELETE or INSERT operation,   all columns are updated and so the mask contains value which has all 1’s in it. This mask is contains value which is formed with Bit values.


*/



/*

Understanding Update mask
It is important to understand the Update mask column in the tracking table. It is named as _$update_mask. The value displayed in the field is hexadecimal but is stored as binary. 

In our example we have three different operations. INSERT and DELETE operations are done on the complete row and not on individual columns. These operations are listed marked masked with 0x1F is translated in binary as 0b11111, which means all the five columns of the table. 

In our example, we had an UPDATE on only two columns – the second and fifth column. This is represented with 0x12 in hexadecimal value ( 0b10010 in binary).  Here, this value stands for second and fifth value if you look at it from the right, as a bitmap. This is a useful way of finding out which columns are being updated or changed.

The tracking table shows  two columns which contains the suffix lsn in them i.e. _$start_lsn and _$end_lsn. These two values correspond to the  Log Sequential Number. This number is associated with committed transaction of the DML operation on the tracked table. 



*/


--show info on cdc tables
USE AdventureWorks; 
GO 
EXEC sys.sp_cdc_help_change_data_capture 
GO


--disable cdc
USE AdventureWorks;

GO

EXECUTE sys.sp_cdc_disable_table 

    @source_schema = N'HumanResources', 

    @source_name = N'Shift',

    @capture_instance = N'HumanResources_Shift';

GO


--disable on a db
USE AdventureWorks 
GO 
EXEC sys.sp_cdc_disable_db 
GO 


/*

In CDC this there is automatic cleanup process that runs at regular intervals. By default the interval is of 3 days but it can be configured. We have observed that, when we enable CDC on the database, there is one additional system stored procedure created with the  name sys.sp_cdc_cleanup_change_table which cleans up all the tracked data at interval.

*/


