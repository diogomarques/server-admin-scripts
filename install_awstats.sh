#!/bin/bash
# Install AWStats.
# Installation instructions: https://help.ubuntu.com/community/AWStats
# Requires: apache2
# Target: Ubuntu server 12.04

# check if user is root
if [ $(id -u) -ne 0 ]; then
        echo "Only root may use this script"
        exit 1
fi

# Obtain a user and password
read -p "username: " username
read -s -p "password: " password

# install awstats
sudo apt-get install -y awstats

# get domain name
#nslookup $HOSTNAME | grep Name | sed 's/\s\+/ /g' | cut -d' ' -f2
domain=$(nslookup $HOSTNAME | grep Name | cut -c7-)

# Create a copy of awstats.conf for each domain:
cp /etc/awstats/awstats.conf /etc/awstats/awstats.${domain}.conf

# Modify the file:
sed -i "s/SiteDomain=\"\"/SiteDomain=\"${domain}\"/g" /etc/awstats/awstats.${domain}.conf
sed -i "s/HostAliases=\"localhost 127.0.0.1\"/HostAliases=\"localhost 127.0.0.1 ${domain}\"/g" /etc/awstats/awstats.${domain}.conf

# Generate the initial stats for AWStats based on existing var/log/apache2/access.log:
/usr/lib/cgi-bin/awstats.pl -config=${domain} -update


# Apache configuration

# Backup
cp /etc/apache2/sites-available/default /etc/apache2/sites-available/"default-bak"$(date +"%Y-%m-%d:%s")

# Add configurations to default
apache_extra_config=" #AWStats config \n                                                     
Alias /awstatsclasses "/usr/share/awstats/lib/" \n
Alias /awstats-icon "/usr/share/awstats/icon/" \n
Alias /awstatscss "/usr/share/doc/awstats/examples/css" \n
ScriptAlias /awstats/ /usr/lib/cgi-bin/ \n
Options ExecCGI -MultiViews +SymLinksIfOwnerMatch  \n"

sed -i "s,</VirtualHost>,$(echo $apache_extra_config) </VirtualHost>,g" /etc/apache2/sites-available/default

# Password protection

# create passwd file
htpasswd -bc /etc/apache2/passwd ${username} ${password}


# Add more configurations
apache_extra_config="<Files "awstats.pl"> \n
AuthUserFile /etc/apache2/passwd \n
AuthName "Restricted Area" \n
AuthType Basic \n
require valid-user \n
</Files> \n"
sed -i "s,</VirtualHost>,$(echo $apache_extra_config) </VirtualHost>,g" /etc/apache2/sites-available/default

# Reload apache
service apache2 restart
