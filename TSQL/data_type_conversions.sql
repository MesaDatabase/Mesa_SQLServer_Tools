--convert from boolean to string
CREATE FUNCTION BOOLEAN_TO_STRING
               (@boolean BIT)
RETURNS VARCHAR(5)
AS
  BEGIN
    IF @boolean = 0 -- false  
      BEGIN
        RETURN 'FALSE'
      END
    
    RETURN 'TRUE'
  END
  
--convert from date to string
CREATE FUNCTION CONVERT_DATE_TO_STRING
               (@date   DATETIME,
                @format VARCHAR(3))
RETURNS VARCHAR(29)
AS
  BEGIN
    IF @format = 'USA'
      BEGIN
        RETURN CONVERT(VARCHAR(13),@date,101)
      END
    
    IF @format = 'ENG'
      BEGIN
        RETURN CONVERT(VARCHAR(13),@date,103)
      END
    
    IF @format = 'GER'
      BEGIN
        RETURN CONVERT(VARCHAR(13),@date,104)
      END
    
    RETURN CONVERT(VARCHAR(29),@date,100)
  END
  
--convert from string to date
CREATE FUNCTION CONVERT_STRING_TO_DATE
               (@string VARCHAR(29))
RETURNS VARCHAR(29)
AS
  BEGIN
    IF ISDATE(@string) = 0
      BEGIN
        RETURN 'please provide a valid date'
      END
    
    RETURN CONVERT(DATETIME,@string)
  END
  
--convert from number to string
/*=============================================================================
{NAME}
-------------------------------------------------------------------------------
ufn_FormatNumberAsString

{DESCRIPTION}
-------------------------------------------------------------------------------
This function simply takes in a number and converts it to a string and pads it
out to @LENGTH characters long, and optionally adds a prefix and/or suffix.

Note that the resulting string will possibly be longer than @LENGTH.  The end
result will be a string of length(prefix) + @LENGTH + length(suffix).  This
means the desired total length must be decided by the caller and accounted for.

    ex. dbo.ufn_FormatNumberAsString(823,10,'/','/') would return the string
        "/0000000823/", which is 12 characters long.

    ex. dbo.ufn_FormatNumberAsString(823,10,'','/') would return the string
        "0000000823/", which is 11 characters long.

    ex. dbo.ufn_FormatNumberAsString(823,10,'','') would return the string
        "0000000823", which is 10 characters long.

Default values are supplied for all parameters except @NUMBER. You can call it
with default values like below.  Note it is different from stored procedures,
where omitting the parameters implies the default.  In functions you must
specify the keyword "default"

    ex. dbo.ufn_FormatNumberAsString(823,DEFAULT,DEFAULT,DEFAULT) would return
        the string "0000000823"

{DEPENDENCIES}
-------------------------------------------------------------------------------


{INPUT PARAMETERS}
-------------------------------------------------------------------------------
@NUMBER - int - ID number to convert to string
@LENGTH (opt) - int - Length to pad with zeros, defaults to 10, maximum 200
@PREFIX (opt) - varchar(20) - character(s) to prepend to the string
@SUFFIX (opt) - varchar(20) - character(s) to append to the string

{OUTPUT PARAMETERS}
-------------------------------------------------------------------------------
None.

{REVISION HISTORY}
-------------------------------------------------------------------------------
05/02/2005 - Damon Clark - Initial.

=============================================================================*/
CREATE FUNCTION dbo.ufn_FormatNumberAsString
(
    @NUMBER int,
    @LENGTH int = 10,
    @PREFIX varchar(20) = '',
    @SUFFIX varchar(20) = ''
)
RETURNS varchar(240) AS
BEGIN
    declare @NewString varchar(240)

    -- Test to make sure length parameter valid
    if @LENGTH > 200
        return ('')
    -- Test to make sure total length of string will be valid
    if @LENGTH + len(@PREFIX) + len(@SUFFIX) > 240
        return ('')

    -- Build numeric part (i.e. 0000000823)
    set @NewString = replicate('0',@LENGTH - len(CAST(@NUMBER AS varchar(200)))) + CAST(@NUMBER AS varchar(200))

    -- If prefix supplied, add it
    if len(@PREFIX) > 0
      set @NewString = @PREFIX + @NewString

    -- If suffix supplied, add it
    if len(@SUFFIX) > 0
      set @NewString = @NewString + @SUFFIX

    return (@NewString)
END