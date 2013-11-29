#!/bin/bash
# Maps a user account public HTML to a registered domain name.
# Requires updating the name server on the registrar control panel.
# GoDaddy example: Visit my account > Domain > Launch > DNS Zone File > Edit > Change A record
# Requires: apache2, userdir
# Target: Ubuntu server 12.04

# check if user is root
if [ $(id -u) -ne 0 ]; then
        echo "Only root may use this script"
        exit 1
fi

# Obtain user and domain
read -p "username (e.g. alice): " username
read -p "domain name (e.g. alicesdomain.com): " domain

# Check if userdir exists
egrep "^$username" /etc/passwd >/dev/null
if [ $? -ne 0 ]; then
        echo "$username account does no exist"
        exit 1
fi

# Crete apache config file
cp user_domain_default.conf /etc/apache2/sites-available/$domain

# Replace domain and user dir in config file
sed -i "s/USER/${username}/g" /etc/apache2/sites-available/${domain}
sed -i "s/DOMAIN/${domain}/g" /etc/apache2/sites-available/${domain}

# Update apache configs
a2ensite $domain

# Restart apache
service apache2 reload
