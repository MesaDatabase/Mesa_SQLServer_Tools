--run query from command line
sqlcmd -Server01.datacenter.us1.company.com -E -s"," -Q"select * from master.sys.databases" -o node1.csv -h 1 -W

--run query for hostlist from command line
FOR /F "usebackq tokens=1,2* companyims=," %i IN (hostlist.txt) do sqlcmd -S%i -E -s"," -Q"select @@servername as server, name, enabled, description, category_id, notify_level_eventlog from msdb.dbo.sysjobs order by name" >> jobs.txt

--run sql file from command line
sqlcmd -S Server01.datacenter.us1.company.com -E -s"," -i Disables_Jobs.sql  >> jobs_disabled.txt

--run sql file for hostlist from command line
FOR /F "usebackq tokens=1,2* companyims=," %i IN (hostlist_some.txt) do sqlcmd -S%i -E -s"," -i Disabled_Jobs.sql  >> jobs_disabled.txt -h -1

--usage
  [-U login id]          [-P password]
  [-S server]            [-H hostname]          [-E trusted connection]
  [-d use database name] [-l login timeout]     [-t query timeout]
  [-h headers]           [-s colseparator]      [-w screen width]
  [-a packetsize]        [-e echo input]        [-I Enable Quoted Identifiers]
  [-c cmdend]            [-L[c] list servers[clean output]]
  [-q "cmdline query"]   [-Q "cmdline query" and exit]
  [-m errorlevel]        [-V severitylevel]     [-W remove trailing spaces]
  [-u unicode output]    [-r[0|1] msgs to stderr]
  [-i inputfile]         [-o outputfile]        [-z new password]
  [-f <codepage> | i:<codepage>[,o:<codepage>]] [-Z new password and exit]
  [-k[1|2] remove[replace] control characters]
  [-y variable length type display width]
  [-Y fixed length type display width]
  [-p[1] print statistics[colon format]]
  [-R use client regional setting]
  [-b On error batch abort]
  [-v var = "value"...]  [-A dedicated admin connection]
  [-X[1] disable commands, startup script, environment variables [and exit]]
  [-x disable variable substitution]
  [-? show syntax summary]
