
Log into the Windows server as a local administrator that has not been assigned the “sysadmin” fixed server role.
Run the following SQL query against the local server to check if the current user has been assigned the “sysadmin” fixed server role.
osql –E –S “localhostsqlexpress” –Q “select is_srvrolemember(‘sysadmin’)”


Download psexec. It’s part of the sysinternals tool set and can be downloaded from Microsoft at: http://technet.microsoft.com/en-us/sysinternals/bb897553.aspx
Type the following command to obtain a “NT AUTHORITYSYSTEM” console with psexec:
psexec –s cmd.exe

Note: The -s switch tells psexec to run cmd.exe as “NT AUTHORITYSYSTEM” .  It does this by creating a new service and configuring it to run as “NT AUTHORITYSYSTEM”.

Type the one of the following command to verify that you are running as “NT AUTHORITYSYSTEM”
whoami
or
echo %username%

Now run the same osql query as before to verify that you have “sysadmin” privileges. This time you should get a 1 back instead of a 0.
osql –E –S “localhostsqlexpress” –Q “select is_srvrolemember(‘sysadmin’)"

If you prefer a GUI tool you can also run management studio express as shown in the screenshots below.
psexec.exe -i -s ssms

PsExec -s -i "C:\Program Files (x86)\Microsoft SQL Server\110\Tools\Binn\ManagementStudio\Ssms.exe"