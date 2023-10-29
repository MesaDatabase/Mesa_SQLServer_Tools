SELECT  * FROM    sys.dm_exec_query_optimizer_info
WHERE   counter = 'order hint'
        AND occurrence > 1