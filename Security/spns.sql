/*
http://msdn.microsoft.com/en-us/library/ms191153(v=sql.110).aspx

A service principal name (SPN) is the name by which a client uniquely identifies an instance of a service. 
The Kerberos authentication service can use an SPN to authenticate a service. 
When a client wants to connect to a service, it locates an instance of the service, composes an SPN for that instance, connects to the service, and presents the SPN for the service to authenticate.

When an application opens a connection and uses Windows Authentication, SQL Server Native Client passes:
	SQL Server computer name
	instance name
	SPN (optional)
If the connection passes an SPN it is used without any changes
If the connection does not pass an SPN, a default SPN is constructed based on the protocol used, server name, and the instance name

In both of the preceding scenarios, the SPN is sent to the Key Distribution Center to obtain a security token for authenticating the connection. 
If a security token cannot be obtained, authentication uses NTLM.


When the Database Engine service starts, it attempts to register the Service Principal Name (SPN). 
If the account starting SQL Server doesn’t have permission to register an SPN in Active Directory Domain Services, this call will fail and a warning message will be logged in the Application event log as well as the SQL Server error log. 
To register the SPN, the Database Engine must be running under a built-in account, such as:
	Local System (not recommended)
	NETWORK SERVICE OR
	An account that has permission to register an SPN, such as a domain administrator account
If SQL Server is not running under one of these accounts, the SPN is not registered at startup and the domain administrator must register the SPN manually.

Beginning with SQL Server 2008, the SPN format is changed in order to support Kerberos authentication on TCP/IP, named pipes, and shared memory. 
The supported SPN formats for named and default instances are as follows.
	Named instance 
		MSSQLSvc/FQDN:[port|instancename], where: 
			MSSQLSvc is the service that is being registered. 
			FQDN is the fully qualified domain name of the server. 
			port is the TCP port number.
			instancename is the name of the SQL Server instance.

	Default instance 
		MSSQLSvc/FQDN:port|MSSQLSvc/FQDN, where: 
			MSSQLSvc is the service that is being registered.
			FQDN is the fully qualified domain name of the server.
			port is the TCP port number.
			
The new SPN format does not require a port number. This means that a multiple-port server or a protocol that does not use port numbers can use Kerberos authentication.

In the case of a TCP/IP connection, where the TCP port is included in the SPN, SQL Server must enable the TCP protocol for a user to connect by using Kerberos authentication.
	MSSQLSvc/fqdn:port				The provider-generated, default SPN when TCP is used. port is a TCP port number.
	MSSQLSvc/fqdn					The provider-generated, default SPN for a default instance when a protocol other than TCP is used. fqdn is a fully-qualified domain name.
	MSSQLSvc/fqdn:InstanceName		The provider-generated, default SPN for a named instance when a protocol other than TCP is used. InstanceName is the name of an instance of SQL Server.
 

Manually register an SPN for a TCP/IP connection:
	setspn -A MSSQLSvc/myhost.redmond.microsoft.com:1433 accountname
 
Manually register a new instance-based SPN:
	Default instance:		setspn -A MSSQLSvc/myhost.redmond.microsoft.com accountname
	Named instance:			setspn -A MSSQLSvc/myhost.redmond.microsoft.com:instancename accountname
	
If an SPN already exists, it must be deleted before it can be reregistered (setspn command with the -D switch)

Service accounts can be used as an SPN. They are specified through the connection attribute for the Kerberos authentication and take the following formats:
	username@domain or domain\username for a domain user account
	machine$@domain or host\FQDN for a computer domain account such as Local System or NETWORK SERVICES.

*/

--auth_scheme column = 'KERBEROS' if Kerberos is enabled for the connection
SELECT net_transport, auth_scheme FROM sys.dm_exec_connections WHERE session_id = @@spid;

/*
2012 AlwaysOn

A Server Principal Name (SPN) must be configured in Active Directory by a domain administrator for each availability group listener name in order to enable Kerberos for the client connection to the availability group listener. 
When registering the SPN, you must use the service account of the server instance that hosts the availability replica. 
For the SPN to work across all replicas, the same service account must be used for all instances in the WSFC cluster that hosts the availability group. 
	setspn -A MSSQLSvc/AG1listener.Adventure-Works.com:1433 corp/svclogin2

*/

