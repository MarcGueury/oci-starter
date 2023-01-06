#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

export JAVAX_SQL_DATASOURCE_DS1_DATASOURCE_URL="##JDBC_URL##"
if [ "$TF_VAR_java_vm" == "graalvm_native" ]; then
  ./helidon -Doracle.jdbc.fanEnabled=false > app.log 2>&1 
else  
  java -jar helidon.jar -Doracle.jdbc.fanEnabled=false > app.log 2>&1
fi
