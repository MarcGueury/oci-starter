#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# ORACLE Instant Client
sudo yum install -y oracle-instantclient-release-el7
sudo yum install -y oracle-instantclient-basic
sudo yum install -y oracle-instantclient-sqlplus

# Install last version of GoLang
sudo yum install -y oracle-golang-release-el7
sudo yum install -y git gcc golang
go get .

# sudo sh -c "echo /usr/lib/oracle/18.3/client64/lib > /etc/ld.so.conf.d/oracle-instantclient.conf" 
# sudo ldconfig
