SELECT 
    DB_NAME(dbid) as DBName, 
    COUNT(dbid) as NumberOfConnections,
    loginame as LoginName
FROM
    sys.sysprocesses
WHERE 
    dbid > 0
GROUP BY 
    dbid, loginame
;

This will show ACTIVE and INACTIVE connections. For showing only the active sessions, use the good Old sp_who2 'ACTIVE'
