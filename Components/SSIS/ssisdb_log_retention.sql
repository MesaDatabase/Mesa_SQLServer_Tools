--21549367
select count(1)
from internal.event_message_context

select count(1) from internal.operations
select min(created_time)
from internal.operations

SELECT CONVERT(bit, property_value) 
FROM [catalog].[catalog_properties]
WHERE property_name = 'OPERATION_CLEANUP_ENABLED'

SELECT CONVERT(INT,property_value)  
FROM [catalog].[catalog_properties]
WHERE property_name = 'RETENTION_WINDOW'

EXEC catalog.configure_catalog RETENTION_WINDOW, 30
