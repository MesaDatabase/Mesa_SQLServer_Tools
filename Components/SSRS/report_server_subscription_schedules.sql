 
 SELECT 
	rpt.Path as ReportPath,
    rpt.Name as ReportName,
	sch.Name as ScheduleName,
    sch.RecurrenceType,
    sch.RecurrenceSubType,  
    sch.RunsEveryHours,  
    sch.RunsEveryDays,  
    sch.RunsEveryWeeks,  
    CASE WHEN len(Sch.RunsEveryWeekDays) > 0 THEN substring(Sch.RunsEveryWeekDays,1,len(Sch.RunsEveryWeekDays)-1) ELSE '' END AS RunsEveryWeekDays,  
    Sch.RunsEveryWeekOfMonth,
    CASE WHEN len(Sch.RunsEveryMonth) > 0 THEN substring(Sch.RunsEveryMonth,1,len(Sch.RunsEveryMonth)-1) ELSE '' END AS RunsEveryMonth,
    CASE WHEN len(Sch.RunsEveryCalendarDays) > 0 THEN substring(Sch.RunsEveryCalendarDays,1,len(Sch.RunsEveryCalendarDays)-1) ELSE '' END AS RunsEveryCalendarDays,  
    Sch.StartDate,
    Sch.NextRunTime,  
    Sch.LastRunTime,  
    sch.EndDate,  
	s.LastStatus,
	s.EventType,
	sch.ScheduleID as SQLAgentJobName
 FROM   
   (SELECT 
		ScheduleID,
        Name,
        CASE WHEN RecurrenceType=1 THEN 'Once'  
			 WHEN RecurrenceType=2 THEN 'Hourly'  
			 WHEN RecurrenceType=3 THEN 'Daily'  
			 WHEN RecurrenceType=4 THEN 'Weekly'  
			 WHEN RecurrenceType in (5,6) THEN 'Monthly'  
        END as RecurrenceType,
        CASE WHEN RecurrenceType=1 THEN 'Once'  
			 WHEN RecurrenceType=2 THEN 'Hourly'  
			 WHEN RecurrenceType=3 THEN 'Daily'  
			 WHEN RecurrenceType=4 and WeeksInterval <= 1 THEN 'Daily'  
			 WHEN RecurrenceType=4 and WeeksInterval > 1 THEN 'Weekly'  
			 WHEN RecurrenceType=5 THEN 'CalendarDaywise'  
			 WHEN RecurrenceType=6 THEN 'WeekWise'  
        END as RecurrenceSubType,
        CASE RecurrenceType  
			 WHEN 2 THEN CONCAT(MinutesInterval/60, ' Hours(s) ' ,MinutesInterval%60,' Minutes(s) ')     
        ELSE '' END as RunsEveryHours,
        ISNULL(CONVERT(VARCHAR(3),DaysInterval),'')  as RunsEveryDays,  
        ISNULL(CONVERT(VARCHAR(3),WeeksInterval),'')  as RunsEveryWeeks,
        CASE WHEN Daysofweek & POWER(2, 0) = POWER(2,0) THEN 'Sun,' ELSE '' END +  
        CASE WHEN Daysofweek & POWER(2, 1) = POWER(2,1) THEN 'Mon,' ELSE '' END +  
        CASE WHEN Daysofweek & POWER(2, 2) = POWER(2,2) THEN 'Tue,' ELSE '' END +  
        CASE WHEN Daysofweek & POWER(2, 3) = POWER(2,3) THEN 'Wed,' ELSE '' END +  
        CASE WHEN Daysofweek & POWER(2, 4) = POWER(2,4) THEN 'Thu,' ELSE '' END +  
        CASE WHEN Daysofweek & POWER(2, 5) = POWER(2,5) THEN 'Fri,' ELSE '' END +  
        CASE WHEN Daysofweek & POWER(2, 6) = POWER(2,6) THEN 'Sat,' ELSE '' END  as RunsEveryWeekDays,
        CASE WHEN MonthlyWeek <= 4 THEN CONVERT(VARCHAR(2),MonthlyWeek)  
			 WHEN MonthlyWeek = 5 THEN 'Last'  
        ELSE '' END as RunsEveryWeekOfMonth,  
        CASE WHEN Month & POWER(2, 0) = POWER(2,0) THEN 'Jan,' ELSE '' END +  
        CASE WHEN Month & POWER(2, 1) = POWER(2,1) THEN 'Feb,' ELSE '' END +  
        CASE WHEN Month & POWER(2, 2) = POWER(2,2) THEN 'Mar,' ELSE '' END +  
        CASE WHEN Month & POWER(2, 3) = POWER(2,3) THEN 'Apr,' ELSE '' END +  
        CASE WHEN Month & POWER(2, 4) = POWER(2,4) THEN 'May,' ELSE '' END +  
        CASE WHEN Month & POWER(2, 5) = POWER(2,5) THEN 'Jun,' ELSE '' END +  
        CASE WHEN Month & POWER(2, 6) = POWER(2,6) THEN 'Jul,' ELSE '' END +  
        CASE WHEN Month & POWER(2, 7) = POWER(2,7) THEN 'Aug,' ELSE '' END +  
        CASE WHEN Month & POWER(2, 8) = POWER(2,8) THEN 'Sep,' ELSE '' END +  
        CASE WHEN Month & POWER(2, 9) = POWER(2,9) THEN 'Oct,' ELSE '' END +  
        CASE WHEN Month & POWER(2, 10) = POWER(2,10) THEN 'Nov,' ELSE '' END +   
        CASE WHEN Month & POWER(2, 11) = POWER(2,11) THEN 'Dec,' ELSE '' END      as RunsEveryMonth,
        CASE WHEN DaysOfMonth & POWER(2, 0) = POWER(2, 0) THEN '1,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 1) = POWER(2, 1) THEN '2,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 2) = POWER(2, 2) THEN '3,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 3) = POWER(2, 3) THEN '4,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 4) = POWER(2, 4) THEN '5,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 5) = POWER(2, 5) THEN '6,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 6) = POWER(2, 6) THEN '7,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 7) = POWER(2, 7) THEN '8,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 8) = POWER(2, 8) THEN '9,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 9) = POWER(2, 9) THEN '10,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 10) = POWER(2, 10) THEN '11,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 11) = POWER(2, 11) THEN '12,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 12) = POWER(2, 12) THEN '13,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 13) = POWER(2, 13) THEN '14,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 14) = POWER(2, 14) THEN '15,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 15) = POWER(2, 15) THEN '16,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 16) = POWER(2, 16) THEN '17,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 17) = POWER(2, 17) THEN '18,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 18) = POWER(2, 18) THEN '19,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 19) = POWER(2, 19) THEN '20,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 20) = POWER(2, 20) THEN '21,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 21) = POWER(2, 21) THEN '22,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 22) = POWER(2, 22) THEN '23,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 23) = POWER(2, 23) THEN '24,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 24) = POWER(2, 24) THEN '25,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 25) = POWER(2, 25) THEN '26,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 26) = POWER(2, 26) THEN '27,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 27) = POWER(2, 27) THEN '28,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 28) = POWER(2, 28) THEN '29,' ELSE '' END +  
        CASE WHEN DaysOfMonth & POWER(2, 29) = POWER(2, 29) THEN '30,' ELSE '' END +   
        CASE WHEN DaysOfMonth & POWER(2, 30) = POWER(2, 30) THEN '31,' ELSE '' END   as RunsEveryCalendarDays,  
        StartDate,
        NextRunTime,
        LastRunTime, 
        EndDate,
        Recurrencetype as RecurrenceTypeId
    FROM Schedule  
) sch  
    left join ReportSchedule rs on Sch.ScheduleID = rs.ScheduleID 
    left join Subscriptions s on rs.SubscriptionID = s.SubscriptionID 
    left join [Catalog] rpt on s.Report_OID = rpt.ItemID 
ORDER BY  rpt.Path,  rpt.Name