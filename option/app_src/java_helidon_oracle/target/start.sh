#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

export JAVAX_SQL_DATASOURCE_DS1_DATASOURCE_URL="##JDBC_URL##"
java -jar helidon.jar -Doracle.jdbc.fanEnabled=false > app.log 2>&1 