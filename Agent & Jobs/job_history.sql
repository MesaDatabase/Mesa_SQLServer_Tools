--all job history
select job_name, run_datetime, run_duration, run_stat
from
(
    select job_name, run_datetime,
        SUBSTRING(run_duration, 1, 2) + ':' + SUBSTRING(run_duration, 3, 2) + ':' +
        SUBSTRING(run_duration, 5, 2) AS run_duration, 
        case when run_status = 0 then 'Failed' when run_status = 1 then 'Succeeded' else 'Other' end as run_stat
    from
    (
        select distinct
            j.name as job_name, 
            run_datetime = CONVERT(DATETIME, RTRIM(run_date)) +  
                (run_time * 9 + run_time % 10000 * 6 + run_time % 100 * 10) / 216e4,
            run_duration = RIGHT('000000' + CONVERT(varchar(6), run_duration), 6), run_status
        from msdb..sysjobhistory h
        inner join msdb..sysjobs j
        on h.job_id = j.job_id
    ) t
) t
order by job_name, run_datetime

--history entry count by job
select j2.name, COUNT(1) from msdb..sysjobhistory j1 (nolock)
  join msdb..sysjobs j2 (nolock) on j1.job_id = j2.job_id
where step_id = 1
group by j2.name
order by j2.name
