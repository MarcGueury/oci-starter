#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install last version of Ruby
sudo yum install -y oracle-release-el7
sudo yum install -y ruby
gem install rails
# ORACLE Instant Client
sudo yum install -y oracle-instantclient-release-el7
sudo yum install -y oracle-instantclient-basic
sudo yum install -y oracle-instantclient-sqlplus
npm install

sudo yum install rh-ruby27 rh-ruby27-ruby-devel
scl enable rh-ruby27 bash
gem install puma
gem install rails

/*
cd /tmp
rails new starter-ruby --api && cd starter-ruby