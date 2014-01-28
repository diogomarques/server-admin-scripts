#!/bin/bash
# Creates a new LAMP user. Sends email confirmation w/ password.
# Target: Unbuntu server 12.04
# Requires: lamp, sendmail

# check if user is root
if [ $(id -u) -ne 0 ]; then
	echo "Only root may add a user to the system"
	exit 1
fi
 
# ask for username
read -p "username: " username
# fail if it already exists
egrep "^$username" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
	echo "$username exists"
	exit 1
fi
 
# ask for email address 2 times
read -p "send confirmation email to: " email
read -p "confirm email: " email_confirm
# fail if confirmation doesn't match
if [ "$email" != "$email_confirm" ]; then
	echo "emails don't match!"
	exit 1
fi
 
# check MySQL admin password	
read -sp "MySQL admin password: " mysql_admin
mysql_login_errors=$(mysql --user=root --password=$mysql_admin -e "" 2>&1 | wc -l)
# fail if it's not correct
if [ $mysql_login_errors -ne 0 ]; then 
	echo "wrong MySQL admin password!"
	exit 1
fi
 
# if all good so far, create the account
# generate passwords for user & mysql
userpass=$(pwgen -AB1)
mysqlpass=$(pwgen -AB1)
mysqlpasshashed=$(mysql --user=root --password=$mysql_admin -e "SELECT PASSWORD('$mysqlpass');" | grep -- "*")
# add user (public_html will be copied from /etc/skel)
adduser --disabled-login --gecos 'User' $username
echo $username:$userpass | chpasswd
chmod og-r /home/$username
# add user to mysql
mysql --user=root --password=$mysql_admin -e "CREATE USER '$username'@'localhost' IDENTIFIED BY PASSWORD '$mysqlpasshashed';"
mysql --user=root --password=$mysql_admin -e "CREATE DATABASE IF NOT EXISTS  $username ;"
mysql --user=root --password=$mysql_admin -e "GRANT ALL PRIVILEGES ON  $username . * TO  '$username'@'localhost';"
echo ""
# send email with passwords
printf "From:$HOSTNAME <no-reply@$HOSTNAME>\nSubject: $HOSTNAME user\nYour account $username has been created.\n\nAccount password: $userpass\nMySQL password: $mysqlpass\n\n Please change your passwords as soon as possible" | sendmail "$email"			
echo "User created. Email with passwords sent to $email."
