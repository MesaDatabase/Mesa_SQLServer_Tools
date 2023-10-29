 
DECLARE
  @complex tinyint 
  , @minlen tinyint
  , @maxlen tinyint  

SET @minlen = 4 --min length of password
SET @maxlen = 8 --max length of password
SET @complex = 4
--  1 all lowercase
--  2 include upper case
--  3 include number
--  4 include punctuation

DECLARE 
  @password varchar(12)
  , @len tinyint
  , @type  tinyint
  , @type2 tinyint

SET @len = 0
SET @password = ''
WHILE @len NOT BETWEEN @minlen and @maxlen
  BEGIN
    SET @len = ROUND(1 + (RAND(CHECKSUM(NEWID())) * @maxlen), 0) + 1
  END
WHILE @len > 0
  BEGIN
    DECLARE @newchar CHAR(1)
    SET @type = ROUND(1 + (RAND(CHECKSUM(NEWID())) * (@complex - 1)), 0)
    IF @type = 1
      SET @newchar = CHAR(ROUND(97 + (RAND(CHECKSUM(NEWID())) * 25), 0))
    IF @type = 2
      SET @newchar = CHAR(ROUND(65 + (RAND(CHECKSUM(NEWID())) * 25), 0))
    IF @type = 3
      SET @newchar = CHAR(ROUND(48 + (RAND(CHECKSUM(NEWID())) * 9), 0))
    IF @type = 4
      BEGIN
        SET @type2 = ROUND(1 + (RAND(CHECKSUM(NEWID())) * 3), 0)    
        IF @type2 = 1
          SET @newchar = CHAR(ROUND(33 + (RAND(CHECKSUM(NEWID())) * 14), 0))
        IF @type2 = 2
          SET @newchar = CHAR(ROUND(58 + (RAND(CHECKSUM(NEWID())) * 6), 0))
        IF @type2 = 3
          SET @newchar = CHAR(ROUND(91 + (RAND(CHECKSUM(NEWID())) * 5), 0))
        IF @type2 = 4
          SET @newchar = CHAR(ROUND(123 + (RAND(CHECKSUM(NEWID())) * 3), 0))
      END
-- remove invalid characters as well as characters easily confused with others
    IF @newchar NOT IN ('b', 'l', 'o', 's', 'I', 'O', 'S', '0', '1', '!', '''', '.', ',', '/', '`', '\', '|')
      BEGIN
        SET @password = @password + @newchar
        SET @len = @len - 1
      END
  END
SELECT @password as Password