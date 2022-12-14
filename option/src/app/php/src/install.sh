#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install last version of PHP
sudo yum install -y oracle-release-el7
sudo yum install -y oracle-php-release-el7 
sudo yum install -y php php-json php-oci8-19c php-mysql

# sudo yum install -y php php-mysql php-json php-fpm
# ORACLE Instant Client
sudo yum install -y oracle-instantclient-release-el7
sudo yum install -y oracle-instantclient-basic
sudo yum install -y oracle-instantclient-sqlplus

if grep -q '##DB_URL##' php.ini.append; then
  sed -i "s!##DB_URL##!$DB_URL!" php.ini.append 
  sudo sh -c "cat php.ini.append >> /etc/php.ini"
else
  echo "DB_URL is already in php.ini.append"
fi

# PHP use apache 
sudo cp html/* /var/www/html/.
sudo cp app.conf /etc/httpd/conf.d/.

# Configure the Apache Listener on 8080
sudo sed -i "s/Listen 80$/Listen 8080/" /etc/httpd/conf/httpd.conf
sudo systemctl restart httpd

