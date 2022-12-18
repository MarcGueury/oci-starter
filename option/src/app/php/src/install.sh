#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install last version of PHP
sudo yum install -y oracle-release-el7
sudo yum install -y oracle-php-release-el7
sudo yum install -y php
sudo yum install -y php-oci8-19c

# sudo yum install -y php php-mysql php-json php-fpm
# ORACLE Instant Client
sudo yum install -y oracle-instantclient-release-el7
sudo yum install -y oracle-instantclient-basic
sudo yum install -y oracle-instantclient-sqlplus

if grep -q '##DB_URL##' app/php.ini.append; then
  echo "DB_URL is already in app/php.ini.append"
else
  sed -i "s!##DB_URL##!$DB_URL!" app/php.ini.append 
  sudo cat app/php.ini.append >> /et/php.ini
fi

# PHP use apache 
sudo cp app/* /var/www/html/.

# Configure the Apache Listener on 8080
sudo sed -i "s/Listen 80$/Listen 8080/" /etc/httpd/conf/httpd.conf
sudo systemctl restart httpd

