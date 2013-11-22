#!/bin/bash
# Change the PHP configuration to allow for larger files.
# Requires: apache2, lamp
# Target: Ubuntu server 12.04

# check if user is root
if [ $(id -u) -ne 0 ]; then
	echo "Only root may change the php configuration"
	exit 1
fi

# ask how large
read -p "new limit in MB: " limit
# fail if it's not number
if [ "$limit" -ne "$limit" ]; then
	exit 1
fi

# backup php.ini
cp /etc/php5/apache2/php.ini /etc/php5/apache2/"php.ini-bak-"$(date +"%Y-%m-%d:%s")

# insert new size condiguration in php.ini
cur_size_conf=$(grep post_max_size /etc/php5/apache2/php.ini)
new_size_conf="post_max_size = $limitM"
sed -i "s/${cur_size_conf}/${new_size_conf}/g" /etc/php5/apache2/php.ini

# restart apache
service apache2 restart
