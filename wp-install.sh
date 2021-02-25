#!/bin/bash -e
clear
dbpass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
dbuser=$(cat /dev/urandom | tr -dc 'a-zA-Z' | fold -w 8 | head -n 1)
dbname=$(cat /dev/urandom | tr -dc 'a-zA-Z' | fold -w 8 | head -n 1)

echo "This setup requires a domain name.  If you do not have one yet, you may"
echo "--------------------------------------------------"
echo "Enter the domain name for your new WordPress site."
echo "(ex. example.org or test.example.org) do not include www or http/s"

# Entering details of the new Wordpress site
read -p "Domain: " url
read -p "Title: " title
read -p "Admin email: " admin_email

email=^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$
while ! [[ "${admin_email}" =~ ${email} ]]; do
        echo "Invalid email:"
        read -p "Enter Valid Email:" admin_email
done

read -p "Admin username: " admin_name
read -sp "Admin password: " admin_pass

#Creating the database
mysql <<EOF
CREATE DATABASE IF NOT EXISTS $dbname;
CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';
GRANT ALL ON $dbname.* TO '$dbuser'@'localhost';
ALTER DATABASE $dbname CHARACTER SET utf8 COLLATE utf8_general_ci;
EOF

# Starting the Wordpress installation process
cd /var/www/html
curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
cp wp-cli.phar /usr/bin/wp

# Download the latest wordpress package using wp-cli
wp core download --allow-root

# Creating wp-config file using credentials
wp core config --dbhost=localhost --dbname=$dbname --dbuser=$dbuser --dbpass=$dbpass --allow-root

chmod 644 wp-config.php

wp core install --path="/var/www/html" --url=$url --title="$title" --admin_name=$admin_name --admin_password=$admin_pass --admin_email=$admin_email --allow-root
wp plugin install wp-fail2ban --allow-root --path="/var/www/html"
wp plugin activate wp-fail2ban --allow-root --path="/var/www/html"
wp plugin install disable-xml-rpc --activate --allow-root --path="/var/www/html"
wp plugin install wp-super-cache --allow-root --path="/var/www/html"
wp plugin activate wp-super-cache --allow-root --path="/var/www/html"

#Fix permission
chown www-data.www-data /var/www/html -R

#Display configuration
echo "========================="
echo "Installation is complete."
echo ""
myip=$(hostname -I | awk '{print$1}')

echo "Welcome to LetsCloud OneClick."
echo ""
echo "In a web browser, you can view: "
echo " * The new WordPress site: http://$myip

Administrator URL:
http://$url/wp-admin or
http://$myip/wp-admin
User: $admin_name
Pass: $admin_pass

On the server:
 * The default web root is located at /var/www/html
 * The must-use WordPress security plugin, fail2ban, is located at
   /var/www/html/wp-content/mu-plugins/fail2ban.php
 * Certbot is preinstalled. Run it to configure HTTPS. See
   https://letscloud.io for more detail.
 * For security, xmlrpc calls are blocked by default.  This block can be
    disabled by running "wp plugin deactivate disable-xml-rpce --allow-root --path="/var/www/html"" in the terminal.

*** IMPORTANT
If you are not using a valid domain, edit wp-config.php and enter the data below:
define( 'WP_HOME', 'http://$myip' );
define( 'WP_SITEURL', 'http://$myip' );

For help and more information, visit https://letscloud.io
********************************************************************************"
