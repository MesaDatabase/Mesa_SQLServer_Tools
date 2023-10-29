USE tempdb 

--drop TABLE dbo.tmp_sp_server_diagnostics 
CREATE TABLE dbo.tmp_sp_server_diagnostics 
               ([create_time] datetime, 
                [component_type] nvarchar(50), 
                [component_name] nvarchar(20), 
				[state] int, 
                [state_desc] nvarchar(20), 
                [data] xml) 

INSERT dbo.tmp_sp_server_diagnostics 

EXEC sys.sp_server_diagnostics 

SELECT create_time, component_name, state, state_desc, data 
FROM dbo.tmp_sp_server_diagnostics 

