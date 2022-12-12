#!/bin/bash
# Build_app.sh
#
# Compute:
# - build the code 
# - create a $ROOT/compute/app directory with the compiled files
# - and a start.sh to start the program
# Docker:
# - build the image
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../../bin/build_common.sh
check_java_version

if [ "$TF_VAR_java_vm" == "graalvm_native" ]; then
  mvn package -Dpackaging=native-image
else 
  mvn package 
fi

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  cp start.sh target/.

  mkdir ../../target/compute/app
  cp -r target/* ../../target/compute/app/.
  # Replace the user and password in the start file
  replace_db_user_password_in_file ../../target/compute/app/start.sh  
else
  docker image rm app:latest
  if [ "$TF_VAR_java_vm" == "graalvm_native" ]; then
    docker build -f Dockerfile.native -t app:latest .
  else
    docker build -t app:latest . 
  fi  
fi  
