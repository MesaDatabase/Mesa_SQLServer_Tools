----Last Day of Previous Month
SELECT DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE()),0))
LastDay_PreviousMonth
----Last Day of Current Month
SELECT DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE())+1,0))
LastDay_CurrentMonth
----Last Day of Next Month
SELECT DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,GETDATE())+2,0))
---First Day of Current Month
DATEADD(month, DATEDIFF(month,0,getdate()),0)
--First Day of Previous Month
DATEADD(month, DATEDIFF(month,0,dateadd(month,-1,getdate())),0)

--format date to yyyymm
(SELECT CAST(CONVERT(nvarchar(6), @start, 112) AS int))

--convert datetime to extract only
-- retrieve only time  
CREATE FUNCTION get_only_time (@date datetime)  RETURNS VARCHAR(15)  AS
BEGIN
  RETURN SUBSTRING(CAST(@date AS VARCHAR(29)), 14, 15)
END

--or date can be passed in
ALTER FUNCTION get_only_time (@string VARCHAR(29))  RETURNS VARCHAR(15)  AS  
BEGIN
  IF ISDATE(@string) = 0  
  BEGIN
  RETURN 'date invalid!'  
  END  
  RETURN SUBSTRING(CAST(CAST(@string AS DATETIME) AS VARCHAR(29)), 14, 15)
END


--add business days to a date
CREATE FUNCTION ADD_DAY
               (@date DATETIME,
                @b    CHAR(1),
                @n    INT)
RETURNS VARCHAR(40)
AS
  BEGIN
    DECLARE  @date1 DATETIME
    
    IF @b = 'n' -- adding non-business days  
      BEGIN
        SELECT @date1 = DATEADD(DD,@n,@date)
      END
    ELSE -- adding business days  
      BEGIN
        DECLARE  @m INT
        
        SET @m = 0
        
        SELECT @date1 = @date
        
        WHILE @n > @m
          BEGIN
            SELECT @date1 = DATEADD(DD,1,@date1)
            
            IF DATEPART(DW,@date1) NOT IN (7,1)
              BEGIN
                SET @m = @m + 1
              END
          END
      END
    
    RETURN CAST(@date1 AS VARCHAR(12))
  END
  
  
--get the next business day
-- get next business day  
-- assumption: first day of the week is Sunday  
CREATE FUNCTION NEXT_BUSINESS_DAY
               (@date DATETIME)
RETURNS VARCHAR(12)
AS
  BEGIN
    DECLARE  @date1 DATETIME,
             @m     INT
    
    SELECT @date1 = @date,
           @m = 0
    
    WHILE @m & LT
     &nbsp;; 1
    
    BEGIN
      SET @date1 = DATEADD(DD,1,@date1)
      
      /*  ** the following line checks for non-business days (1 and 7)  
 ** IF your business days are different, change the following line to   
 ** comply with your schedule   
 */
      IF DATEPART(DW,@date1) NOT IN (1,7)
        BEGIN
          SET @m = @m + 1
        END
    END
    
    RETURN CAST(@date1 AS VARCHAR(12))
  END
  
  
--number of business days between two dates
CREATE PROC NUMBER_OF_BUSINESS_DAYS_BETWEEN
           @date1 SMALLDATETIME,
           @date2 SMALLDATETIME
AS
  DECLARE  @n INT,
           @m INT
  
  -- first find the number of business days in the same week as @date1
  SET @m = 0
  
  SELECT @n = DATEDIFF(DD,@date1,@date2)
  
  WHILE @date2 > @date1
    BEGIN
      SET @date1 = DATEADD(DD,1,@date1)
      
      IF DATEPART(DW,@date1) IN (7,1)
        BEGIN
          SET @m = @m + 1
        END
    END
  
  SELECT 'number of business days = ',
         @n - @m
GO

--number of seconds, minutes or hours since midnight
-- number of seconds since midnight: 
CREATE PROC TIME_INTERVALS_SINCE_MIDNIGHT
           @time_interval CHAR(1)
AS
  IF @time_interval = 'm'
    BEGIN
      SELECT DATEDIFF(MI,CAST(CAST(GETDATE() AS VARCHAR(13)) + '12:00:00AM' AS DATETIME),
                      GETDATE())
    END
  ELSE
    IF @time_interval = 'h'
      BEGIN
        SELECT DATEDIFF(HH,CAST(CAST(GETDATE() AS VARCHAR(13)) + '12:00:00AM' AS DATETIME),
                        GETDATE())
      END
    ELSE
      IF @time_interval = 's'
        BEGIN
          SELECT DATEDIFF(SS,CAST(CAST(GETDATE() AS VARCHAR(13)) + '12:00:00AM' AS DATETIME),
                          GETDATE())
        END
      ELSE
        BEGIN
          RAISERROR ('time interval needs to be h, m, or s. please select one.',16,1)
          
          RETURN
        END
        
--is a date a business day
-- is a date a business day   
-- assumption is that first day of the week is sunday   
CREATE PROC business_day @date_var smalldatetime   AS 
IF datepart(dw, @date_var) 
BETWEEN (@@datefirst-5) AND (@@datefirst -1)   
BEGIN  
 SELECT CAST(@date_var AS VARCHAR(13)) + ' is a ' + DATENAME(dw, @date_var)   + '; it is a business day!'   
 END  
 ELSE 
 SELECT CAST(@date_var AS VARCHAR(13)) + ' is a ' + DATENAME(dw, @date_var)   + '; it is NOT a business day!'
        
--strip time off of datetime
cast(floor(cast (START_TIME as float )) as datetime)