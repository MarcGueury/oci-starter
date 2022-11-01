#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

sudo yum install python3
python3 -m pip install cx_Oracle --upgrade 
sudo pip3 install Flask
sudo pip3 install -U flask-cors
sudo pip3 install flask-mysql
