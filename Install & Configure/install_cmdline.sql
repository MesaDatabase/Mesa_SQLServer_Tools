--create a folder C:\Temp\updates
--copy latest SP and CU into it

--copy ConfigurationFile.ini to C:\Temp
--update parameters in config file
----reference of parameters: https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-2017

--mount iso

--update passwords in the command below
--open cmd as administrator
--run below command
E:\Setup.exe /IACCEPTSQLSERVERLICENSETERMS /SAPWD="sapwd" /SQLSVCPASSWORD="sqlsvcpwd" /AGTSVCPASSWORD="agentpwd" /ConfigurationFile="C:\Temp\ConfigurationFile.INI " /UpdateEnable=TRUE /UpdateSource="C:\Temp\updates"
