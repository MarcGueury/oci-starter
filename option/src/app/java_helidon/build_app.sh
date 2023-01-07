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
java_build_common

replace_db_user_password_in_file src/main/resources/META-INF/microprofile-config.properties

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
    # This will not work with GraalVM 22+ Helidon 3 works with only GraalVM 21.3. See : https://github.com/helidon-io/helidon/issues/5299
    mvn package -Pnative-image -Dnative.image.buildStatic -DskipTests
  else 
    mvn package -DskipTests
  fi
  exit_on_error  
  cp start.sh target/.
  mkdir -p ../../target/compute/app
  cp -r target/* ../../target/compute/app/.
else
  docker image rm ${TF_VAR_prefix}-app:latest
  if [ "$TF_VAR_java_vm" == "graalvm-native" ]; then
    docker build -f Dockerfile.native -t ${TF_VAR_prefix}-app:latest . 
  else
    docker build -t ${TF_VAR_prefix}-app:latest . 
  fi
  exit_on_error  
fi  
