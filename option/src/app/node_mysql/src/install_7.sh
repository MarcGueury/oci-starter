#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Install last version of NodeJS
sudo yum install -y oracle-nodejs-release-el7 oracle-release-el7
sudo yum install -y nodejs
npm install
