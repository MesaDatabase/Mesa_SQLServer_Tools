select ItemPath, DATEPART(year,TimeStart) as [Year], DATEPART(week,TimeStart) as WeekNumber, count(1) as RunCnt
from dbo.ExecutionLog3
where ByteCount > 0
  --and ItemAction <> 'ConceptualSchema'
  and RequestType <> 'Refresh Cache'
  and ItemPath like '/path/%'
group by ItemPath, DATEPART(year,TimeStart), DATEPART(week,TimeStart)
order by 1,2,3