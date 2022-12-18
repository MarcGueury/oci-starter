#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install last version of PHP
sudo yum install -y oracle-release-el7
sudo yum install -y php php-mysql php-json php-fpm
# ORACLE Instant Client
sudo yum install -y oracle-instantclient-release-el7
sudo yum install -y oracle-instantclient-basic
sudo yum install -y oracle-instantclient-sqlplus
npm install

sudo mkdir -p /usr/share/nginx/app
sudo cp -r app/* /usr/share/nginx/app/.
