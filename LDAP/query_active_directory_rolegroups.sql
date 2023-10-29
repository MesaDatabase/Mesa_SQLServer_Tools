select *
  from openquery
(adsi,' 
       select givenname, sn, mail, department, title, sAMAccountName, userAccountControl, telephoneNumber, physicalDeliveryOfficeName, objectGUID, objectCategory
       from ''LDAP://DC=ufcunet,DC=ad''
       where objectClass = ''Group''
	     and cn=''Role-*''
       ')
order by sAMAccountName
