select getdate(), * FROM sys.dm_exec_query_optimizer_info
WHERE counter in ('order hint','join hint')
   AND occurrence > 1