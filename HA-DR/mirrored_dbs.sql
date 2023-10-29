-- Find if LOG SHIPPING is enabled for a database (2005-2012)
SELECT primary_database FROM msdb..log_shipping_primary_databases

-- Find if Database Mirroring is enabled for a database (2005-2012)
SELECT
A.name,
CASE
    WHEN B.mirroring_state is NULL THEN 'Mirroring not configured'
    ELSE 'Mirroring configured'
END as MirroringState
FROM
sys.databases A
INNER JOIN sys.database_mirroring B
ON A.database_id=B.database_id
--WHERE a.database_id > 4
ORDER BY A.NAME

