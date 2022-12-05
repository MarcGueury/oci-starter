#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

export DB_USER=##DB_USER##
export DB_PASSWORD=##DB_PASSWORD##
export SPRING_APPLICATION_JSON='{ "db.url": "##JDBC_URL##" }'
export TF_VAR_java_vm=##TF_VAR_java_vm##

# Start Java with Native or JIT (JDK/GraalVM)
if [ "$TF_VAR_java_vm" == "graalvm_native" ]; then
  ./demo > app.log 2>&1 
else  
  java -jar demo-0.0.1-SNAPSHOT.jar > app.log 2>&1 
fi