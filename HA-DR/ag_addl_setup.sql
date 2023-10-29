systeminfo > C:\TEMP\sysinfo.txt


2494036
2616514
2687741


Import-Module FailoverClusters

$nameResource = "saieprdclur"
Get-ClusterResource $nameResource | Get-ClusterParameter
Get-ClusterResource $nameResource | Set-ClusterParameter HostRecordTTL 300


Name: Service_MSTR_AMDB

Password: j$@Src11268845

please make the password as never expire


alter availability group AG_AMDBR MODIFY REPLICA ON N'SERVERR01' 
	WITH (SECONDARY_ROLE(READ_ONLY_ROUTING_URL=N'TCP://SERVERR01:1433'))

alter availability group AG_AMDBR MODIFY REPLICA ON N'SERVERR02' 
	WITH (SECONDARY_ROLE(READ_ONLY_ROUTING_URL=N'TCP://SERVERR02:1433'))

/*READ_ONLY_ROUTING_LIST should contain the order in which read-intent connections should be routed when the replica is the primary node*/
	alter availability group AG_AMDBR MODIFY REPLICA ON N'SERVERR01' 
	WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST=(N'SERVERR02', N'SERVERR01')))

	alter availability group AG_AMDBR MODIFY REPLICA ON N'SERVERR02' 
	WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST=(N'SERVERR01', N'SERVERR02')))


alter availability group AG_AMDBT MODIFY REPLICA ON N'SERVERT01' 
	WITH (SECONDARY_ROLE(READ_ONLY_ROUTING_URL=N'TCP://SERVERT01:1433'))

alter availability group AG_AMDBT MODIFY REPLICA ON N'SERVERT02' 
	WITH (SECONDARY_ROLE(READ_ONLY_ROUTING_URL=N'TCP://SERVERT02:1433'))

/*READ_ONLY_ROUTING_LIST should contain the order in which read-intent connections should be routed when the replica is the primary node*/
	alter availability group AG_AMDBT MODIFY REPLICA ON N'SERVERT01' 
	WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST=(N'SERVERT02', N'SERVERT01')))

	alter availability group AG_AMDBT MODIFY REPLICA ON N'SERVERT02' 
	WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST=(N'SERVERT01', N'SERVERT02')))