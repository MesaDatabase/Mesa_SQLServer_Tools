Import-Module sqlps -DisableNameChecking

function Get-SQLServices { 

Invoke-Sqlcmd -Serverinstance ADCPRDB01 -Database DBAAudit -Query "if exists(select * from sysobjects where name = 'tblSQLServices') begin drop table dbo.tblSQLServices end"
Invoke-Sqlcmd -Serverinstance ADCPRDB01 -Database DBAAudit -Query "if not exists(select * from sysobjects where name = 'tblSQLServices') begin create table dbo.tblSQLServices (ServerName varchar(50), ServiceName varchar(255), State varchar(25), StartMode varchar(25)) end"

   
#foreach ( $svr in get-content C:\UFCUDBA\DbAudit\servername.txt)
#{
#
#$Script:procInfo = Get-WmiObject -ComputerName (get-content C:\UFCUDBA\DbAudit\servername.txt) -class Win32_Service -Filter "Name like '%SQL%'" | Select Name,state,StartMode,SystemName
#$d = $procInfo.Name
#$s = $procInfo.State
#$a = $procInfo.StartMode
#$b = $procInfo.SystemName
#$query2 = "insert into dbo.tblSQLServices select '" + $d + "','" + $s + "','" + $a + "'" + $b + "'"
#Invoke-Sqlcmd -Serverinstance ADCPRDB01 -Database DBAAudit -Query $query2
#
#}

#Invoke-Sqlcmd -Serverinstance ADCPRDB01 -Database DBAAudit -Query "if exists(select * from sysobjects where name = 'tblSQLServices') begin drop table dbo.tblSQLServices end"

}

Get-SQLServices

