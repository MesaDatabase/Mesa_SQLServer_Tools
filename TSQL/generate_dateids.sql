set @s = @start
declare @i int 
declare @z int
set @i = CONVERT(nvarchar(8),@start,112)
set @z = CONVERT(nvarchar(8),@end,112)

while @s <= @end
begin
	insert into #t1 (DateId)
	select @i
	set @s = @s + 1
	set @i = CONVERT(nvarchar(8),@s,112)
end	
