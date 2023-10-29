SELECT 
ssi.id
, object_name(ssi.id) AS tblName
, ssi.name as idxName
, stats_date(ssi.id,ssi.indid) as StatsDate
, ssi.indid
, ssi.rowcnt
, ssi.rowmodctr
, cast(ssi.rowmodctr as decimal)/cast(ssi.rowcnt as decimal) as ChangedRowsRatio
, ss.no_recompute AS IsAutoUpdateOff
, 'UPDATE STATISTICS ' + object_name(ssi.id) + ' ' + ssi.name + ';' as UpdateStatsStatement
--select *
FROM sys.sysindexes ssi left join sys.stats ss
ON ssi.name = ss.name
WHERE ssi.id > 100
AND indid > 0
AND ssi.rowcnt > 500
and stats_date(ssi.id,ssi.indid) < '2012-01-01'
--AND (ssi.rowmodctr/ssi.rowcnt) > 0.15 -- enter a relevant number
ORDER BY 4

DBCC SHOW_STATISTICS ('table', 'PK_pk') WITH STAT_HEADER

