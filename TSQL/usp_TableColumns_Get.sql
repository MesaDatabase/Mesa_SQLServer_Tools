USE [AkcelerantCopy]
GO

/****** Object:  UserDefinedFunction [ETL].[usp_TableColumns_Get]    Script Date: 10/27/2020 9:45:54 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO












CREATE FUNCTION [ETL].[usp_TableColumns_Get]
(
	@SchemaTableName varchar(255)
)
RETURNS varchar(max)
AS
BEGIN
    -- Declare the return variable here
   DECLARE @colList varchar(max)

	DECLARE @cMaxId int
	DECLARE @cId int
	DECLARE @cName varchar(255)

	SET @cId = 1
	SET @colList = ''

	DECLARE @cols TABLE (ColId int, ColName varchar(255))
	INSERT INTO @cols (ColId, ColName)
	SELECT 
		c.column_id, 
		c.name
	FROM sys.all_columns AS c
	  JOIN sys.objects AS o ON c.object_id = o.object_id
	WHERE schema_name(o.schema_id) + '.' + object_name(o.object_id) = @SchemaTableName
	  AND c.name NOT IN ('ExportCreateDate','IsDeleted','CxSum','StagingId','RunLogId','RecordCreateDate','RecordModifiedDate','RecordDeletedDate','VersionId','OperationType')
	  --AND c.column_id < 5

	SELECT @cMaxId = MAX(ColId) FROM @cols
	SELECT TOP 1 @cId = ColId, @cName = ColName FROM @cols ORDER BY ColId

	WHILE EXISTS (SELECT TOP 1 * FROM @cols)
	BEGIN
		SET @colList = @colList + @cName

		IF @cId < @cMaxId SET @colList = @colList + ', '

		DELETE FROM @cols WHERE ColId = @cId

		SELECT TOP 1 @cId = ColId, @cName = ColName FROM @cols ORDER BY ColId
	END

    -- Return the result of the function
    RETURN @colList
END

GO


