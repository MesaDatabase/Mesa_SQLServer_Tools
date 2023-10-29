--logins with blank passwords
SELECT name FROM sys.sql_logins 
WHERE PWDCOMPARE('', password_hash) = 1 ;

--logins with password same as username
SELECT * FROM sys.sql_logins 
WHERE PWDCOMPARE(name, password_hash) = 1 ;

--search for common passwords
SELECT name FROM sys.sql_logins 
WHERE PWDCOMPARE('password', password_hash) = 1 ;


--common passwords
Baseball 
111111 
dragon 
letmein 
monkey 
qwerty 
abc123 
12345678 
123456 
Password
welcome
jesus
mustang
password1
iloveyou
football
111111
ninja
password
123456
12345678
abc123
qwerty
monkey
letmein
dragon
111111
baseball
iloveyou
trustno1
1234567
sunshine
master
123123
welcome
shadow
ashley
football
jesus
michael
ninja
mustang
password1
