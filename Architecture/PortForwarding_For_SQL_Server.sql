--compile information
x.xxx.xxx.xxx = logship1
10.xx.xx.xx = cloudserver1
1.x.xx.xxx = server1\instance1
1.x.xx.xxx = server1\instance2

--use this query to get sql uptime
--2000
select SQL_Server_Start_Time = min(login_time) from sysprocesses
--2005+
SELECT sqlserver_start_time FROM sys.dm_os_sys_info

--check sql logs for on start date for "Server is listening on" to find port

--on forwarding server, check port forwards
netsh interface portproxy show all
33302	10.xx.xx.xx	1251
33301	1.x.xx.xx1	1465
33300	1.x.xx.xx2	1567

--on forwarding server, add port forward
netsh interface portproxy add v4tov4 listenport=33302 listenaddress=10.177.200.164 connectport=1251 connectaddress=10.91.81.31

--from workstation
add sql aliases:
	alias name = make one up
	server = forwarding server ip
	protocol = tcp
	port no = forwarding server listenport

--check connections from ssms
connect to alias name
