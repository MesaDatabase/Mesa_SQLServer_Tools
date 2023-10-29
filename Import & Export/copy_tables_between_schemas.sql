USE TEMPDB
GO

SET NOCOUNT ON
GO    

DECLARE @SqlString nvarchar(max) = ''
DECLARE @CopyFromSchema Varchar(50)
DECLARE @CopyToSchema Varchar(200)
DECLARE @ObjectName Varchar(100)

---- Set The Paramenter
---- Now you can pass multiple parameters in @ObjectName
SET @CopyFromSchema = 'Marketing'
SET @CopyToSchema = 'Sales, Account, Economics, Employee, Manager'
SET @ObjectName = 'Table_1, Table_2, Table_3'


DECLARE @TotalSchema INT
DECLARE @TotalObject INT  
DECLARE @SchemaCount INT
DECLARE @ObjectCount INT
DECLARE @XML XML
DECLARE @Flag INT
DECLARE @SchemaName Varchar(100)
DECLARE @CurrentObjectName NVarchar(max)
DECLARE @ObjectsWithSchema NVarchar(max)
DECLARE @ObjectType varchar(100)
DECLARE @Count_Total int = -1
DECLARE @Count_Current int = 1
DECLARE @Count_String Varchar(max) = ''

DECLARE @SchemaList Table (ID INT Identity(1,1), SchemaName Varchar(200))
DECLARE @ObjectList Table (CreateOrder INT , DropOrder INT , ObjectName Varchar(200), ObjectType char(100), ObjectCreateDate Datetime, ObjectDefinitation Datetime)

SET @SqlString = ''
SET @SchemaName = ''
SET @SchemaCount = 1
SET @ObjectCount = 1
SET @Flag = 0

---- Get All Schema List
SET @XML = N'<root><Schema>' + replace(@CopyToSchema,',','</Schema><Schema>') + '</Schema></root>'
INSERT INTO @SchemaList
SELECT RTRIM(LTRIM(t.value('.','varchar(100)'))) from @XML.nodes('//root/Schema') as a(t)
SELECT @TotalSchema = max(ID) from @SchemaList

---- Get All Object List
SET @XML = N'<root><Schema>' + replace(@ObjectName,',','</Schema><Schema>') + '</Schema></root>'
INSERT INTO @ObjectList ( ObjectName )
SELECT RTRIM(LTRIM(t.value('.','varchar(100)'))) from @XML.nodes('//root/Schema') as a(t)


SET @ObjectsWithSchema = ''
select @ObjectsWithSchema=@ObjectsWithSchema+'Object_ID(''['+@CopyFromSchema+'].'+OBJECTNAME+'''),' from @ObjectList
select @ObjectsWithSchema=SUBSTRING(@ObjectsWithSchema,1,LEN(@ObjectsWithSchema)-1)


---- Check @CopyFromSchema Variable 
IF NOT EXISTS ( SELECT 1 FROM sys.schemas WHERE NAME = @CopyFromSchema)
BEGIN
	RAISERROR ('SCHEMA NOT FOUND. PLEASE CHECK "@CopyFromSchema" Parameter.',16,1)
	RETURN
END

---- Check @CopyToSchema Variable 
IF ((SELECT COUNT(*) FROM sys.schemas WHERE name IN (SELECT SchemaName FROM  @SchemaList))!= @TotalSchema)
BEGIN
	RAISERROR ('ONE OR MORE SCHEMA NOT FOUND. PLEASE CHECK "@CopyToSchema" Parameter.',16,1)
	RETURN
END

---- Check @ObjectName Variable 
SET @SqlString = 'SELECT @Flag_OUT =  Count(*) FROM sys.objects WHERE [object_id] IN ('+@ObjectsWithSchema+')'
EXEC Sp_executesql @SqlString,N'@Flag_OUT int OUTPUT',@Flag_OUT = @Flag OUTPUT


IF (@Flag!=@TotalObject)
BEGIN
	RAISERROR('SOME OBJECT(S) NOT FOUND. PLEASE CHECK "@ObjectName" Parameter.',16,1)
	RETURN
END


---- Update @ObjectList Table

UPDATE OBJ_LST SET
	OBJ_LST.ObjectType = ALL_Obj.type_desc, 
	OBJ_LST.ObjectCreateDate = ALL_Obj.create_date
FROM @ObjectList OBJ_LST
INNER JOIN SYS.all_objects ALL_Obj
on ALL_Obj.name = OBJ_LST.ObjectName AND SCHEMA_NAME(ALL_Obj.SCHEMA_ID)= @CopyFromSchema


UPDATE OBJ_LST SET OBJ_LST.CreateOrder = Obj_Rank_Table.CreateOrder,
			       OBJ_LST.DropOrder = Obj_Rank_Table.DropOrder
FROM @ObjectList OBJ_LST
INNER JOIN
(
	SELECT ROW_NUMBER() OVER(ORDER BY ObjectCreateDate ASC) AS CreateOrder,
		   ROW_NUMBER() OVER(ORDER BY ObjectCreateDate DESC) AS DropOrder,
		   ObjectName, ObjectType FROM @ObjectList
) AS Obj_Rank_Table
ON OBJ_LST.ObjectName = Obj_Rank_Table.ObjectName 
AND OBJ_LST.ObjectType = Obj_Rank_Table.ObjectType

SELECT @TotalObject = max(CreateOrder) from @ObjectList


IF EXISTS(SELECT * FROM tempdb.sys.tables where Object_ID = OBJECT_ID('tempdb.dbo.Table_Col_String'))  
	DROP TABLE [tempdb].[dbo].[Table_Col_String]

IF EXISTS(SELECT * FROM tempdb.sys.tables where Object_ID = OBJECT_ID('tempdb.dbo.Table_Index_String'))  
	DROP TABLE [tempdb].[dbo].[Table_Index_String]

IF EXISTS(SELECT * FROM tempdb.sys.tables where Object_ID = OBJECT_ID('tempdb.dbo.Table_Const_String'))  
	DROP TABLE [tempdb].[dbo].[Table_Const_String]


CREATE TABLE [tempdb].[dbo].[Table_Col_String]
(
	[TableName] [sysname] NOT NULL,
	[ColumnName] [sysname] NULL,
	[column_id] [int] NOT NULL,
	[Column_Text] [nvarchar](max) NULL,
) 


CREATE TABLE [tempdb].[dbo].[Table_Index_String]
(
	[Idx_Column_Order] [bigint] NULL,
	[SchemaName] [nvarchar](128) NULL,
	[TableName] [sysname] NOT NULL,
	[ConstraintName] [sysname] NULL,
	[index_id] [int] NOT NULL,
	[type_desc] [nvarchar](60) NULL,
	[is_primary_key] [bit] NULL,
	[is_unique_constraint] [bit] NULL,
	[index_column_id] [int] NULL,
	[column_id] [int] NULL,
	[key_ordinal] [tinyint] NULL,
	[is_descending_key] [bit] NULL,
	[is_included_column] [bit] NULL,
	[ColumnName] [sysname] NULL,
	[Index_String] [nvarchar](max) NULL
) 


CREATE TABLE [tempdb].[dbo].[Table_Const_String]
(
	[SchemaName] [nvarchar](128) NULL,
	[TableName] [sysname] NULL,
	[Const_ID] [int] NOT NULL,
	[Constraint_String] [nvarchar](max) NULL
)



---++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---- GET DETIALS OF TABLE COLUMNS. LIKE DATA TYPE, SIZE
---++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SET @SqlString = '
WITH TableColumns
AS
(
	SELECT TAB.[name] AS TableName, TAb.object_id,
	Col.[Name] AS ColumnName, Col.[column_id], Col.[user_type_id], Col.[max_length], Col.[precision], Col.[scale], 
	Col.[is_nullable], Col.[is_identity], Col.[is_computed], Col.[default_object_id], Col.[is_sparse], 
	TYP.[name] AS DataType,TAB.create_date, 
	idColumns.seed_value, idColumns.increment_value,
	COM_COL.[definition]
	 FROM SYS.COLUMNS COL
	INNER JOIN SYS.TYPES TYP
	ON COL.user_type_id = TYP.user_type_id
	INNER JOIN SYS.TABLES TAB
	ON TAB.object_id = COL.object_id
	LEFT JOIN sys.identity_columns idColumns
	ON idColumns.object_id = Col.object_id AND Col.is_identity = 1
	LEFT JOIN sys.computed_columns COM_COL
	ON COL.object_id = COM_COL.object_id AND COl.is_computed = 1
	WHERE Schema_Name(TAB.Schema_ID) ='''+@CopyFromSchema+'''
	AND TAB.name in ('''+REPLACE(REPLACE(@ObjectName,' ',''),',',''',''')+''')

)
INSERT INTO [tempdb].[dbo].[Table_Col_String]
SELECT  TableName,ColumnName,column_id
, ''[''+ColumnName+''] ''+ 
CASE WHEN is_computed = 1 Then ''AS (''+[definition]+'')'' 
ELSE '' [''+ DataType +''] '' END +
CASE is_identity WHEN 1 THEN ''Identity (''+Convert(Varchar(10),increment_value)+'',''+Convert(Varchar(10),seed_value)+'')'' ELSE '''' END +
CASE 
	
	WHEN DataType in (''binary'',''char'') Then ''(''+Convert(Varchar(10),max_length)+'')'' 
	WHEN DataType in (''nchar'') Then ''(''+Convert(Varchar(10),(max_length/2))+'')''  
	WHEN DataType in (''nvarchar'') AND max_length != -1 Then ''(''+Convert(Varchar(10),(max_length/2))+'')''  
	WHEN DataType in (''nvarchar'') AND max_length = -1  Then ''(MAX)'' 
	WHEN DataType in (''varbinary'', ''varChar'') AND max_length = -1 Then ''(MAX)'' 
	WHEN DataType in (''varbinary'', ''varChar'') AND max_length != -1 Then ''(''+Convert(Varchar(10),max_length)+'')''
	WHEN DataType in (''decimal'',''numeric'') Then ''(''+Convert(Varchar(10),[precision])+'', ''++Convert(Varchar(10),(scale))+'')'' 
	ELSE ''''
 END +
CASE is_sparse WHEN 1 THEN '' SPARSE ''ELSE '''' END +
CASE WHEN IS_computed = 1 THEN '''' WHEN Is_Nullable = 1 THEN '' NULL '' ELSE '' NOT NULL '' END AS Column_Text
FROM TableColumns
ORDER BY create_date,column_id'
EXEC (@sqlString)

---++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---- GET DETIALS OF TABLE PRIMARY KEY, UNIQUE KEY AND INDEX PART -I
---++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SET @SqlString = '
;WITH IndexString
AS
(
	SELECT 
	--TAb.object_id,Tab.name,
	--idx.*,IDX_COL.*, Col.NAME 
	Schema_Name(TAB.schema_id) AS SchemaName,
	TAB.name AS TableName,idx.name AS ConstraintName,
	IDX.index_id,Idx.type_desc,idx.is_primary_key,idx.is_unique_constraint,
	IDX_Col.index_column_id, IDX_COL.column_id,IDX_COL.key_ordinal,IDX_COL.is_descending_key, IDX_col.is_included_column,
	COL.Name AS ColumnName
	FROM SYS.indexes IDX
	INNER JOIN SYS.TABLES TAB
	ON IDX.object_id = TAB.object_id
	LEFT JOIN SYS.index_columns IDX_COL
	ON IDX.object_id = IDX_COL.object_id
	and IDX.index_id = IDX_COL.index_id
	LEFT JOIN SYS.COLUMNS COL
	ON IDX_COL.object_id = COL.object_id 
	AND IDX_COL.column_id = COL.column_id 
)
INSERT INTO [tempdb].[dbo].[Table_Index_String]
SELECT DISTINCT 
DENSE_RANK() OVER(Partition By TableName, index_id ORDER BY TableName, index_id, key_ordinal, is_included_column), * ,''''
FROM IndexString 
WHERE ConstraintName IS NOT NULL
AND SchemaName =''Marketing''
AND TableName in ('''+REPLACE(REPLACE(@ObjectName,' ',''),',',''',''')+''')'
EXEC (@sqlString)

---++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---- GET DETIALS OF TABLE PRIMARY KEY, UNIQUE KEY AND INDEX PART -II
---++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SET @SqlString = '
UPDATE IndexString SET [Index_String] = 
''
			IF NOT EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = ''''IDX_''+Convert(Varchar(10),index_id)+''_''+type_desc+''_''+SchemaName+''_''+TableName  COLLATE SQL_Latin1_General_CP1_CI_AS +'''''') ''+
				CASE WHEN is_primary_key = 1 THEN ''
					ALTER TABLE [''+SchemaName+''].[''+TableName+'']''+'' ADD PRIMARY KEY ''+type_desc+'' (''
					+ STUFF((SELECT '', [''+T2.ColumnName+'']''+ CASE WHEN T2.is_descending_key = 1 THEN '' DESC '' ELSE '' ASC '' END FROM [tempdb].[dbo].[Table_Index_String] T2 
						WHERE IndexString.SchemaName = T2.SchemaName AND IndexString.TableName = T2.TableName 
							AND IndexString.index_id = T2.index_id  AND T2.is_included_column = 0 FOR XML PATH('''')),1,2,'''') +'') '' 

					 WHEN is_unique_constraint = 1 THEN ''
					ALTER TABLE [''+SchemaName+''].[''+TableName+'']''+'' ADD UNIQUE ''+type_desc+'' (''
					+ STUFF((SELECT '', [''+T2.ColumnName+'']''+ CASE WHEN T2.is_descending_key = 1 THEN '' DESC '' ELSE '' ASC '' END FROM [tempdb].[dbo].[Table_Index_String] T2 
						WHERE IndexString.SchemaName = T2.SchemaName AND IndexString.TableName = T2.TableName 
							AND IndexString.index_id = T2.index_id  AND T2.is_included_column = 0 FOR XML PATH('''')),1,2,'''') +'') '' 	
					ELSE 
					''
					CREATE ''+type_desc+'' INDEX [IDX_''+Convert(Varchar(10),index_id)+''_''+type_desc+''_''+SchemaName+''_''+TableName  COLLATE SQL_Latin1_General_CP1_CI_AS +''] ON [''+SchemaName+''].[''+TableName+'']''+
'' (''+ STUFF((SELECT '', [''+T2.ColumnName+'']''+ CASE WHEN T2.is_descending_key = 1 THEN '' DESC '' ELSE '' ASC '' END FROM [tempdb].[dbo].[Table_Index_String] T2 
	WHERE IndexString.SchemaName = T2.SchemaName AND IndexString.TableName = T2.TableName 
	AND IndexString.index_id = T2.index_id  AND T2.is_included_column = 0 FOR XML PATH('''')),1,2,'''') +'')''  
END + '' '' +
CASE WHEN is_included_column = 1 THEN
'' INCLUDE (''
			+ STUFF((SELECT '', [''+T2.ColumnName+'']'' FROM [tempdb].[dbo].[Table_Index_String] T2 
				WHERE IndexString.SchemaName = T2.SchemaName AND IndexString.TableName = T2.TableName 
					AND IndexString.index_id = T2.index_id  AND T2.is_included_column = 1 FOR XML PATH('''')),1,2,'''') +'') 
					''
	ELSE ''
	''
END 
FROM [tempdb].[dbo].[Table_Index_String]AS IndexString '
EXEC (@sqlString)

---++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---- GET DETIALS OF TABLE CONSTRAINTS
---++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SET @SqlString = '

WITH TAB_Const
AS
(
	select 
	ALL_Const.[constid], ALL_Const.[id] AS TABLE_ID, ALL_Const.[Colid],
	SCHEMA_NAME(TAB.schema_id) AS SchemaName, TAB.name AS TableName,COL.name AS ColumnName,
	ISNULL(ISNULL(D_Const.type_desc,C_Const.type_desc),F_Const.type_desc) AS Const_Type,
	ISNULL(ISNULL(D_Const.[name] ,C_Const.[name]),F_Const.[name] ) AS Const_Name,
	ISNULL(D_Const.[definition] ,C_Const.[definition]) AS Const_Definition
	FROM sysconstraints ALL_Const
	LEFT JOIN sys.default_constraints D_Const
	ON ALL_Const.constid = D_Const.object_id
	LEFT JOIN sys.check_constraints C_Const
	ON ALL_Const.constid = C_Const.object_id
	LEFT JOIN Sys.all_objects F_Const
	ON ALL_Const.constid = F_Const.object_id AND F_Const.[type] =''F''
	LEFT JOIN SYS.TABLES TAB
	ON TAB.object_id = ALL_Const.id
	LEFT JOIN SYS.columns COL
	ON COL.object_id = ALL_Const.id 
	AND COL.column_id  = ALL_Const.colid
),
foreignKey
AS 
(
	select FK.name,FK.type_desc ,FKC.*
	,(SELECT Name from sys.tables Tab where FKC.parent_object_id = Tab.object_id)  AS parent_object_Name
	,(SELECT Name from sys.Columns Col where FKC.parent_object_id = Col.object_id AND FKC.parent_column_id = Col.column_id)  AS parent_column_Name
	,(SELECT Name from sys.tables Tab where FKC.referenced_object_id = Tab.object_id)  AS referenced_object_Name
	,(SELECT Name from sys.Columns Col where FKC.referenced_object_id = Col.object_id AND FKC.referenced_column_id = Col.column_id)  AS referenced_object_Column_Name
	 from sys.foreign_keys FK
	LEFT JOIN sys.foreign_key_columns FKC
	ON FK.object_id = FKC.constraint_object_id
)
INSERT INTO [tempdb].[dbo].[Table_Const_String]
select DISTINCT TAB_Const.SchemaName,TAB_Const.TableName,
Dense_Rank() over(partition by TAB_Const.TableName order by TAB_Const.[constid]) AS Const_ID,
''
			IF NOT EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = ''''''+Const_Type+''__''+Convert(Varchar(10),Dense_Rank() over(partition by TAB_Const.TableName order by TAB_Const.[constid])) +''_''+
SchemaName+''_''+TableName  COLLATE SQL_Latin1_General_CP1_CI_AS +'''''')'' +

CASE Const_Type 
WHEN ''FOREIGN_KEY_CONSTRAINT''
	THEN 
	 ''
					ALTER TABLE [''+SchemaName+''].[''+parent_object_Name+''] Add constraint ''+Const_Type+''__''+Convert(Varchar(10),Dense_Rank() over(partition by TAB_Const.TableName order by TAB_Const.[constid])) +''_''+
SchemaName+''_''+TableName  COLLATE SQL_Latin1_General_CP1_CI_AS+
	 '' FOREIGN KEY (''+STUFF((SELECT '', ''+parent_column_Name FROM foreignKey T2 WHERE T1.constraint_object_id = T2.constraint_object_id FOR XML PATH('''')),1,2,'''')+'')''+ 
	 '' REFERENCES [''+SchemaName +''].[''+ referenced_object_Name+''] (''+STUFF((SELECT '', ''+ referenced_object_Column_Name FROM foreignKey T2 WHERE T1.constraint_object_id = T2.constraint_object_id FOR XML PATH('''')),1,2,'''')+'')''
ELSE
	''
					ALTER TABLE [''+SchemaName+''].[''+TableName+''] ADD CONSTRAINT ''+CASE Const_Type 
	WHEN ''DEFAULT_CONSTRAINT'' THEN ''DEFAULT_CONSTRAINT__''
	WHEN ''CHECK_CONSTRAINT'' THEN ''CHECK_CONSTRAINT__''
	END
	+Convert(Varchar(10),Dense_Rank() over(partition by TAB_Const.TableName order by TAB_Const.[constid])) + ''_''+
	+SchemaName+''_''+TableName
	+CASE Const_Type 
	WHEN ''DEFAULT_CONSTRAINT'' THEN '' DEFAULT ('' + Const_Definition +'') FOR [''+ ColumnName +''] ''
	WHEN ''CHECK_CONSTRAINT'' THEN '' CHECK ('' + Const_Definition +'')''
	END
END AS Constraint_String
--INTO Table_Const_String
FROM TAB_Const
LEFT JOIN foreignKey T1
ON constraint_object_id = T1.constraint_object_id AND TAB_Const.Const_Name = T1.Name
WHERE TAB_Const.Const_Type IS NOT NULL
AND SchemaName ='''+@CopyFromSchema+'''
AND TableName in ('''+REPLACE(REPLACE(@ObjectName,' ',''),',',''',''')+''')'
EXEC (@sqlString)



SET @SqlString='
SET XACT_ABORT ON
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION
'


WHILE ( @TotalSchema >= @SchemaCount )
BEGIN
	SELECT @SchemaName = SchemaName FROM @SchemaList WHERE ID = (@SchemaCount)

	IF (@SchemaCount=1)
	BEGIN
		SET  @SqlString = @SqlString+'
		SELECT ''[ BEFORE ]'',Schema_ID,SCHEMA_NAME(Schema_ID) AS ''Schema_Name'',Name,create_date,modify_date 
		FROM SYS.OBJECTS WHERE Name IN ('''+REPLACE(REPLACE(@ObjectName,' ',''),',',''',''')+''') ORDER BY CREATE_DATE DESC, MODIFY_DATE DESC
		DECLARE @SQL nvarchar(max)
		'
	END
	
----- GENERATE DROP TABLE SCRIPT
			
	SET @ObjectCount = 1

	WHILE (@TotalObject >= @ObjectCount)
	BEGIN
		SELECT @CurrentObjectName = ObjectName , @ObjectType = ObjectType FROM @ObjectList WHERE DropOrder = (@ObjectCount)

		IF (@ObjectType in ('USER_TABLE'))
		BEGIN
			SET @SqlString=@SqlString+'

			 ----##################### ['+@SchemaName+'].['+@CurrentObjectName+']  #####################----

			IF EXISTS (SELECT 1 FROM sys.Objects WHERE NAME ='''+@CurrentObjectName+''' AND SCHEMA_ID= SCHEMA_ID('''+@SchemaName+'''))
				DROP TABLE ['+@SchemaName+'].['+@CurrentObjectName+']'
				
			SET @ObjectCount = @ObjectCount + 1
		END
	END


	----- GENERATE CREATE TABLE SCRIPT
	SET @ObjectCount = 1

	WHILE (@TotalObject >= @ObjectCount)
	BEGIN
		SELECT @CurrentObjectName = ObjectName , @ObjectType = ObjectType FROM @ObjectList WHERE CreateOrder = (@ObjectCount)

		IF (@ObjectType in ('USER_TABLE'))
		BEGIN
			SET @SqlString=@SqlString+'

			 ----$$$$$$$$$$$$$$$$$$$$$ ['+@SchemaName+'].['+@CurrentObjectName+']  $$$$$$$$$$$$$$$$$$$$$----

			CREATE TABLE ['+@SchemaName+'].['+@CurrentObjectName+'] (
				'

				SET @Count_Total = -1
				SET @Count_String = ''
				SET @Count_Current = 1 

				----+++++++++++++++++++++++++++++++++++++++++++++++++
				---- GENERATE TABLE COLUMNS
				----+++++++++++++++++++++++++++++++++++++++++++++++++
				SET @Count_Current = 1
				SELECT @Count_Total = -1 

				SELECT @Count_Total = MAX(column_id) From [tempdb].[dbo].[Table_Col_String] WHERE TableName = @CurrentObjectName

				WHILE (@Count_Current <= @Count_Total)
				BEGIN
					SELECT @Count_String = Column_Text FROM [tempdb].[dbo].[Table_Col_String] WHERE TableName = @CurrentObjectName AND column_id = @Count_Current

					SET @SqlString = @SqlString + @Count_String 

					IF (@Count_Current < @Count_Total)
						SET @SqlString = @SqlString + ' , '

					SET @Count_Current = @Count_Current + 1
				END
				SET @SqlString = @SqlString + ' ) 
				'




				----+++++++++++++++++++++++++++++++++++++++++++++++++
				---- GENERATE TABLE INDEX
				----+++++++++++++++++++++++++++++++++++++++++++++++++
				
				SET @Count_Total = -1
				SET @Count_String = ''
				SET @Count_Current = 1 

				SELECT @Count_Total = MAX(Index_id) From  [tempdb].[dbo].[Table_Index_String] WHERE TableName = @CurrentObjectName

				WHILE (@Count_Current <= @Count_Total)
				BEGIN
				
					SELECT TOP 1 @Count_String = Index_String FROM [tempdb].[dbo].[Table_Index_String] WHERE TableName = @CurrentObjectName AND Index_id = @Count_Current
					SET @SqlString = @SqlString + @Count_String 

					SET @Count_Current = @Count_Current + 1
				END

				SET @SqlString = REPLACE(REPLACE(@SqlString,'_'+@CopyFromSchema+'_','_'+@SchemaName+'_'),'['+@CopyFromSchema+']','['+@SchemaName+']')


	
				----+++++++++++++++++++++++++++++++++++++++++++++++++
				---- GENERATE TABLE CONSTRAINTS
				----+++++++++++++++++++++++++++++++++++++++++++++++++

				SET @Count_Total = -1
				SET @Count_String = ''
				SET @Count_Current = 1 

				SELECT @Count_Total = MAX(Const_ID) From  [tempdb].[dbo].[Table_Const_String] WHERE TableName = @CurrentObjectName

				WHILE (@Count_Current <= @Count_Total)
				BEGIN
					SELECT @Count_String = Constraint_String FROM [tempdb].[dbo].[Table_Const_String] WHERE TableName = @CurrentObjectName AND Const_ID = @Count_Current
					SET @SqlString = @SqlString + @Count_String 

					SET @Count_Current = @Count_Current + 1
				END

				SET @SqlString = REPLACE(REPLACE(@SqlString,'_'+@CopyFromSchema+'_','_'+@SchemaName+'_'),'['+@CopyFromSchema+']','['+@SchemaName+']')
		END

		SET @ObjectCount = @ObjectCount + 1
	END
	
	SET @SchemaCount = @SchemaCount + 1
END


SET @SqlString = @SqlString +'
IF @@ERROR<>0 AND @@TRANCOUNT>0 ROLLBACK TRANSACTION
IF @@TRANCOUNT>0 COMMIT TRANSACTION

SELECT ''[ AFTER ]'',Schema_ID,SCHEMA_NAME(Schema_ID) AS ''Schema_Name'',Name,create_date,modify_date 
FROM SYS.OBJECTS WHERE Name in ('''+REPLACE(REPLACE(@ObjectName,' ',''),',',''',''')+''')  ORDER BY CREATE_DATE DESC, MODIFY_DATE DESC
'

IF EXISTS(SELECT * FROM tempdb.sys.tables where Object_ID = OBJECT_ID('tempdb.dbo.Table_Col_String'))  
	DROP TABLE [tempdb].[dbo].[Table_Col_String]

IF EXISTS(SELECT * FROM tempdb.sys.tables where Object_ID = OBJECT_ID('tempdb.dbo.Table_Index_String'))  
	DROP TABLE [tempdb].[dbo].[Table_Index_String]

IF EXISTS(SELECT * FROM tempdb.sys.tables where Object_ID = OBJECT_ID('tempdb.dbo.Table_Const_String'))  
	DROP TABLE [tempdb].[dbo].[Table_Const_String]

--PRINT @SqlString
EXEC (@SqlString)

SET NOCOUNT OFF
GO    






----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---- Script for create testing environment. 
----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



/************************************ CREATE OBJECTS SCRIPT ************************************/


----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---- 1. SELECT TEMPDB
----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GO
USE tempdb
GO

----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---- 2. Create schemaes
----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE SCHEMA Marketing
GO
CREATE SCHEMA Sales
GO
CREATE SCHEMA Account
GO
CREATE SCHEMA Economics
GO
CREATE SCHEMA Employee
GO
CREATE SCHEMA Manager
GO

----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---- 2. Check the schemaes
----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SELECT * FROM sys.schemas WHERE [schema_id]>4 and [schema_id]<16000
GO


----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---- 3 Create tables only in Marketing Schema
----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE TABLE Marketing.Table_1 
	(
		T1_Col1_PK int IDENTITY (1,1) PRIMARY KEY,
		T1_Col2 bigint Unique,
		T1_Col3 binary,
		T1_Col4 bit DEFAULT (0),
		T1_Col5 char(10) CHECK (T1_Col5 != 'TEST'),
		T1_Col6 date,
		T1_Col7 datetime,
		T1_Col8 datetime2,
		T1_Col9 datetimeoffset,
		T1_Col10 decimal,
		T1_Col11 decimal (10,2),
		T1_Col12 float,
		T1_Col13 geography
	)
GO

CREATE TABLE Marketing.Table_2
	( 
		T2_Col1_FK int References Marketing.TABLE_1(T1_Col1_PK),
		T2_Col2 geometry,
		T2_Col3 hierarchyid,
		T2_Col4 image,
		T2_Col5 geometry,
		T2_Col6 money,
		T2_Col7 nchar (28),
		T2_Col8 ntext,
		T2_Col9 numeric,
		T2_Col10 nvarchar(100),
		T2_Col11 nvarchar(MAX),
		T2_Col12 real,
		T2_Col13 smalldatetime,
	)
GO

CREATE TABLE Marketing.Table_3
	( 

		T3_Col1 smallint,
		T3_Col2 smallmoney,
		T3_Col3_ComputedColumn AS (T3_Col1 + T3_Col2),
		T3_Col4 sql_variant,
		T3_Col5 sysname,
		T3_Col6 text,
		T3_Col7 time,
		T3_Col8 timestamp,
		T3_Col9 tinyint,
		T3_Col10 uniqueidentifier,
		T3_Col11 varbinary,
		T3_Col12 varchar (123),
		T3_Col13 varchar(MAX) SPARSE NULL,
		T3_Col14 xml
	)
GO

WAITFOR DELAY '00:00:05'
GO
CREATE NONCLUSTERED INDEX IDX_NCL_Marketing_TABLE_1 ON Marketing.TABLE_1 (T1_Col10, T1_Col11)
CREATE CLUSTERED INDEX IDX_NCL_Marketing_TABLE_2 ON Marketing.TABLE_2 (T2_Col1_FK, T2_Col12 DESC)
CREATE CLUSTERED INDEX IDX_CL_Marketing_TABLE_3 ON Marketing.TABLE_3 (T3_Col1)
CREATE NONCLUSTERED INDEX IDX_1_NCL_Marketing_TABLE_3 ON Marketing.TABLE_3 (T3_Col2)
CREATE NONCLUSTERED INDEX IDX_2_NCL_Marketing_TABLE_3 ON Marketing.TABLE_3 (T3_Col2) INCLUDE (T3_Col9, T3_Col14)
GO




----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---- 4. Check the table and views
----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SELECT TOP 15 SCHEMA_ID, SCHEMA_NAME([schema_id]), name, create_date, TYPE FROM sys.objects WHERE TYPE IN ('U', 'V', 'P','FN') 
ORDER BY  CONVERT(datetime,convert(varchar(100),create_date,100)) DESC ,type,name 
GO



/************************************ DROP or CLEAR OBJECTS SCRIPT ************************************/


----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---- 1. Drop Tables
----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE Marketing.Table_3
GO
DROP TABLE Marketing.Table_2
GO
DROP TABLE Marketing.Table_1
GO
	DROP TABLE Sales.Table_3
	GO
	DROP TABLE Sales.Table_2
	GO
	DROP TABLE Sales.Table_1
	GO
DROP TABLE Account.Table_3
GO
DROP TABLE Account.Table_2
GO
DROP TABLE Account.Table_1
GO
	DROP TABLE Economics.Table_3
	GO
	DROP TABLE Economics.Table_2
	GO
	DROP TABLE Economics.Table_1
	GO
DROP TABLE Employee.Table_3
GO
DROP TABLE Employee.Table_2
GO
DROP TABLE Employee.Table_1
GO
	DROP TABLE Manager.Table_3
	GO
	DROP TABLE Manager.Table_2
	GO
	DROP TABLE Manager.Table_1
	GO



----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
----- 5. Drop Schema
----++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

DROP SCHEMA Marketing
GO
DROP SCHEMA Sales
GO
DROP SCHEMA Account
GO
DROP SCHEMA Economics
GO
DROP SCHEMA Employee
GO
DROP SCHEMA Manager
GO