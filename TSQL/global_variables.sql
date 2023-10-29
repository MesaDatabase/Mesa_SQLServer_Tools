select 
  @@CONNECTIONS,
  @@CPU_BUSY,
  @@CURSOR_ROWS,
  @@DATEFIRST,
  @@DBTS,
  @@DEF_SORTORDER_ID,
  @@DEFAULT_LANGID,
  @@ERROR,
  @@FETCH_STATUS,
  @@IDENTITY,
  @@IDLE,
  @@IO_BUSY,
  @@LANGID,
  @@LANGUAGE,
  @@LOCK_TIMEOUT,
  @@MAX_CONNECTIONS,
  @@MAX_PRECISION,
  @@MICROSOFTVERSION,
  @@NESTLEVEL,
  @@OPTIONS,
  @@PACK_RECEIVED,
  @@PACK_SENT,
  @@PACKET_ERRORS,
  @@PROCID,
  @@REMSERVER,
  @@ROWCOUNT,
  @@SERVERNAME,
  @@SPID,
  @@TEXTSIZE,
  @@TIMETICKS,
  @@TOTAL_ERRORS,
  @@TOTAL_READ,
  @@TOTAL_WRITE,
  @@TRANCOUNT,
  @@VERSION

/* 
  @@CONNECTIONS = The number of logins or attempted logins since SQL Server was last started
  @@CPU_BUSY = The amount of time, in ticks, that the CPU has spent doing SQL Server work since the last time SQL Server was started.  Multiply by @@timeticks to get cpu microseconds.
  @@CURSOR_ROWS = Returns the number of qualifying rows currently in the last cursor opened on the connection
  @@DATEFIRST = The first day of the week to a number from 1 through 7
  @@DBTS = Returns the value of the current timestamp data type for the current database. This timestamp is guaranteed to be unique in the database
  @@DEF_SORTORDER_ID = ? something about the sort order
  @@DEFAULT_LANGID = ?
  @@ERROR = contains the error number of the most recent tsql error, 0 indicates that no error has occurred
  @@FETCH_STATUS = contains an integer specifying the status of the last FETCH cursor statement; The available options are: 0=row successfully fetched; –1=no data could be fetched; –2 row fetched is missing or some other error occurred. A value of –1 can indicate that there is no data to FETCH, or that the fetch has reached the end of the data.
  @@IDENTITY = Contains the IDENTITY field value of the most recently inserted, updated, or deleted row.
  @@IDLE = The amount of time, in ticks, that SQL Server has been idle since it was last started.  Multiply by @@timeticks to get cpu microseconds.
  @@IO_BUSY = The amount of time, in ticks, that SQL Server has spent doing input and output operations since it was last started. Multiply by @@timeticks to get cpu microseconds. 
  @@LANGID = The local language id of the language currently in use
  @@LANGUAGE = The name of the language currently in use
  @@LOCK_TIMEOUT = Contains an integer specifying the timeout value for locks, in seconds. Lock timeout is used when a resource needs to be exclusively locked for inserts, updates, deletes, and selects. The default is 10.
  @@MAX_CONNECTIONS = The maximum number of simultaneous connections that can be made with SQL Server in this computer environment
  @@MAX_PRECISION = Returns the precision level used by decimal and numeric data types as currently set in the server
  @@MICROSOFTVERSION = SQL Server version SELECT @@MicrosoftVersion / 0x01000000
  @@NESTLEVEL = Contains an integer specifying the nesting level of the current process. The maximum is 16.
  @@OPTIONS = ?
  @@PACK_RECEIVED = The number of input packets read by SQL Server since it was last started
  @@PACK_SENT = The number of output packets written by SQL Server since it was last started
  @@PACKET_ERRORS = The number of errors that have occurred while SQL Server was sending and receiving packets
  @@PROCID = Returns the object identifier (ID) of the current Transact-SQL module. A Transact-SQL module can be a stored procedure, user-defined function, or trigger
  @@REMSERVER = Returns the name of the remote SQL Server database server as it appears in the login record. To be deprecated.
  @@ROWCOUNT = Contains the number of rows affected by the most recent SELECT, INSERT, UPDATE, or DELETE command. A single-row SELECT always returns a @@ROWCOUNT value of either 0 (no row selected) or 1. 
  @@SERVERNAME = Contains the instance name
  @@SPID = Contains the server process ID of the current process
  @@TEXTSIZE = The current value of the set textsize option, which specifies the maximum length, in bytes, of text or image data to be returned with a select statement. Defaults to 32K
  @@TIMETICKS = The number of microseconds per tick. The amount of time per tick is machine dependent
  @@TOTAL_ERRORS = The number of errors that have occurred while SQL Server was reading or writing
  @@TOTAL_READ = The number of disk reads by SQL Server since it was last started
  @@TOTAL_WRITE = The number of disk writes by SQL Server since it was last started
  @@TRANCOUNT = Contains the number of currently active transactions
  @@VERSION = Contains the version number and date and time of its installation
*/