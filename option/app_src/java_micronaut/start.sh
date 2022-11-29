#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

export DB_USER=##DB_USER##
export DB_PASSWORD=##DB_PASSWORD##
export JDBC_URL="##JDBC_URL##"
java -jar demo-0.1.jar > app.log 2>&1 
