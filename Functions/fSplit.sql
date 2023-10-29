USE [master]
GO
/****** Object:  UserDefinedFunction [dbo].[fSplit]    Script Date: 01/20/2015 13:31:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[fSplit] 
(  
	@delimiter varchar(5), 
    @list varchar(max),
    @fieldToReturn int
) 
returns varchar(max)
AS 
begin

declare @temp table (FieldNum int, Value varchar(max))
declare @return varchar(max)
declare @stringLen int 
declare @i int
set @i = 1

while len(@list) > 0 or @i <= @fieldToReturn
	begin 
		select @stringLen = (case CHARINDEX(@delimiter, @list) 
							 when 0 then LEN(@list)
							 else (CHARINDEX(@delimiter, @list) -1)
							 end) 
		
        insert into @temp
        select @i, substring(@list,1,@stringLen)
            
        select @list = (case (len(@list) - @stringLen) 
						when 0 then '' 
						else right(@list,LEN(@list) - @stringLen - 1) 
						end) 
		set @i = @i + 1
     end
      
set @return = (select Value from @temp temp where FieldNum = @fieldToReturn)
return @return
      
 end

