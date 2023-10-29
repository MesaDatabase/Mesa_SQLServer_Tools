SELECT SDER.[statement_start_offset],   
  SDER.[statement_end_offset],  
  CASE   
     WHEN SDER.[statement_start_offset] > 0 THEN  
        --The start of the active command is not at the beginning of the full command text 
        CASE SDER.[statement_end_offset]  
           WHEN -1 THEN  
              --The end of the full command is also the end of the active statement 
              SUBSTRING(DEST.TEXT, (SDER.[statement_start_offset]/2) + 1, 2147483647) 
           ELSE   
              --The end of the active statement is not at the end of the full command 
              SUBSTRING(DEST.TEXT, (SDER.[statement_start_offset]/2) + 1, (SDER.[statement_end_offset] - SDER.[statement_start_offset])/2)   
        END  
     ELSE  
        --1st part of full command is running 
        CASE SDER.[statement_end_offset]  
           WHEN -1 THEN  
              --The end of the full command is also the end of the active statement 
              RTRIM(LTRIM(DEST.[text]))  
           ELSE  
              --The end of the active statement is not at the end of the full command 
              LEFT(DEST.TEXT, (SDER.[statement_end_offset]/2) +1)  
        END  
     END AS [executing statement],  
  DEST.[text] AS [full statement code]  
FROM sys.[dm_exec_requests] SDER CROSS APPLY sys.[dm_exec_sql_text](SDER.[sql_handle]) DEST  
WHERE SDER.session_id = 53 
ORDER BY SDER.[session_id], SDER.[request_id]