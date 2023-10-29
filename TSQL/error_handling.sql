IF OBJECTPROPERTY(OBJECT_ID('dbo.dba_logError_sp'), N'IsProcedure') = 1
BEGIN
    DROP PROCEDURE dbo.dba_logError_sp;
    PRINT 'Procedure dba_logError_sp dropped';
END;
Go

IF OBJECTPROPERTY(OBJECT_ID('dbo.dba_errorLog'), N'IsTable') IS Null
BEGIN

    CREATE TABLE dbo.dba_errorLog
    (         errorLog_id       INT IDENTITY(1,1)
            , errorType         CHAR(3)     
                CONSTRAINT [DF_errorLog_errorType] DEFAULT 'sys'
            , errorDate         DATETIME   
                CONSTRAINT [DF_errorLog_errorDate] DEFAULT(GETDATE())
            , errorLine         INT
            , errorMessage      NVARCHAR(4000)
            , errorNumber       INT
            , errorProcedure    NVARCHAR(126)
            , procParameters    NVARCHAR(4000)
            , errorSeverity     INT
            , errorState        INT
            , databaseName      NVARCHAR(255)
        CONSTRAINT PK_errorLog_errorLogID PRIMARY KEY CLUSTERED
        (
            errorLog_id 
        )
    );

    PRINT 'Table dba_errorLog created';

END;
Go


SET ANSI_Nulls ON;
SET Ansi_Padding ON;
SET Ansi_Warnings ON;
SET ArithAbort ON;
SET Concat_Null_Yields_Null ON;
SET NOCOUNT ON;
SET Numeric_RoundAbort OFF;
SET Quoted_Identifier ON;
Go

CREATE PROCEDURE dbo.dba_logError_sp
(
    /* Declare Parameters */
      @errorType            CHAR(3)         = 'sys'
    , @app_errorProcedure   VARCHAR(50)     = ''
    , @app_errorMessage     NVARCHAR(4000)  = ''
    , @procParameters       NVARCHAR(4000)  = ''
    , @userFriendly         BIT             = 0
    , @forceExit            BIT             = 1
    , @returnError          BIT             = 1
)
AS
/*********************************************************************************
    Name:       dba_logError_sp

    Author:     Michelle F. Ufford, http://sqlfool.com

    Purpose:    Retrieves error information and logs in the dba_errorLog table.
   
                @errorType = options are "app" or "sys"; "app" are custom
                             application errors, i.e. business logic errors;
                             "sys" are system errors, i.e. PK errors

                @app_errorProcedure = stored procedure name, needed for app errors

                @app_errorMessage = custom app error message
               
                @procParameters = optional; log the parameters that were passed
                                  to the proc that resulted in an error

                @userFriendly = displays a generic error message if = 1

                @forceExit = forces the proc to rollback and exit; mostly useful
                             for application errors.

                @returnError = returns the error to the calling app if = 1
                            

    Called by:  Another stored procedure

    Date        Initials    Description
    ----------------------------------------------------------------------------
    2008-12-16  MFU         Initial Release
*********************************************************************************
    Exec dbo.dba_logError_sp
        @errorType          = 'app'
      , @app_errorProcedure = 'someTableInsertProcName'
      , @app_errorMessage   = 'Some app-specific error message'
      , @userFriendly       = 1
      , @forceExit          = 1
      , @returnError        = 1;
*********************************************************************************/

SET NOCOUNT ON;
SET XACT_Abort ON;

BEGIN

    /* Declare Variables */
    DECLARE @errorNumber            INT
            , @errorProcedure       VARCHAR(50)
            , @dbName               sysname
            , @errorLine            INT
            , @errorMessage         NVARCHAR(4000)
            , @errorSeverity        INT
            , @errorState           INT
            , @errorReturnMessage   NVARCHAR(4000)
            , @errorReturnSeverity  INT
            , @currentDateTime      SMALLDATETIME;

    DECLARE @errorReturnID TABLE (errorID VARCHAR(10));

    /* Initialize Variables */
    SELECT @currentDateTime = GETDATE();

    /* Capture our error details */
    IF @errorType = 'sys'
    BEGIN

        /* Get our system error details and hold it */
        SELECT
              @errorNumber      = Error_Number()
            , @errorProcedure   = Error_Procedure()
            , @dbName           = DB_NAME()
            , @errorLine        = Error_Line()
            , @errorMessage     = Error_Message()
            , @errorSeverity    = Error_Severity()
            , @errorState       = Error_State()&nbsp;;

    END
    ELSE
    BEGIN

        /* Get our custom app error details and hold it */
        SELECT
              @errorNumber      = 0
            , @errorProcedure   = @app_errorProcedure
            , @dbName           = DB_NAME()
            , @errorLine        = 0
            , @errorMessage     = @app_errorMessage
            , @errorSeverity    = 0
            , @errorState       = 0&nbsp;;

    END;

    /* And keep a copy for our logs */
    INSERT INTO dbo.dba_errorLog
    (
          errorType
        , errorDate
        , errorLine
        , errorMessage
        , errorNumber
        , errorProcedure
        , procParameters
        , errorSeverity
        , errorState
        , databaseName
    )
    OUTPUT Inserted.errorLog_id INTO @errorReturnID
    VALUES
    (
          @errorType
        , @currentDateTime
        , @errorLine
        , @errorMessage
        , @errorNumber
        , @errorProcedure
        , @procParameters
        , @errorSeverity
        , @errorState
        , @dbName
    );

    /* Should we display a user friendly message to the application? */
    IF @userFriendly = 1
        SELECT @errorReturnMessage = 'An error has occurred in the database (' + errorID + ')'
        FROM @errorReturnID;
    ELSE
        SELECT @errorReturnMessage = @errorMessage;

    /* Do we want to force the application to exit? */
    IF @forceExit = 1
        SELECT @errorReturnSeverity = 15
    ELSE
        SELECT @errorReturnSeverity = @errorSeverity;

    /* Should we return an error message to the calling proc? */
    IF @returnError = 1
        RAISERROR
        (
              @errorReturnMessage
            , @errorReturnSeverity
            , 1
        ) WITH NoWait;

    SET NOCOUNT OFF;
    RETURN 0;

END
Go