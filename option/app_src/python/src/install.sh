#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

sudo yum install python3

# XXXX Oracle
# sudo yum install -y oracle-instantclient-release-el7
# sudo yum install -y oracle-instantclient-basic
# sudo yum install -y oracle-instantclient-sqlplus
sudo pip3 install oracledb

# Flask
sudo pip3 install Flask
sudo pip3 install -U flask-cors

# Mysql
sudo pip3 install flask-mysql
