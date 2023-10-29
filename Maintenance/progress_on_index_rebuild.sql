--show progress on running index rebuild

;WITH cte AS
(
SELECT
object_id,
index_id,
partition_number,
rows,
ROW_NUMBER() OVER(PARTITION BY object_id, index_id, partition_number ORDER BY partition_id) as rn
FROM sys.partitions
)
SELECT
   object_name(cur.object_id) as TableName,
   cur.index_id,
   cur.partition_number,
   PrecentDone =
      CASE
         WHEN pre.rows = 0 THEN 0
      ELSE
         ((cur.rows * 100.0) / pre.rows)
      END,
   pre.rows - cur.rows as MissingRows
FROM cte as cur
INNER JOIN cte as pre on (cur.object_id = pre.object_id) AND (cur.index_id = pre.index_id) AND (cur.partition_number = pre.partition_number) AND (cur.rn = pre.rn +1)
ORDER BY 4