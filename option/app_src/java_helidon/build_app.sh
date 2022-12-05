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
. $SCRIPT_DIR/../bin/build_common.sh
check_java_version

# Replace the user and password in the configuration file (XXX)
CONFIG_FILE=src/main/resources/META-INF/microprofile-config.properties
sed -i "s/##DB_USER##/$TF_VAR_db_user/" $CONFIG_FILE
sed -i "s/##DB_PASSWORD##/$TF_VAR_db_password/" $CONFIG_FILE

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  if [ "$TF_VAR_java_vm" == "graalvm_native" ]; then
    # This will not work with GraalVM 22+ Helidon 3 works with only GraalVM 21.3. See : https://github.com/helidon-io/helidon/issues/5299
    mvn package -Pnative-image -Dnative.image.buildStatic -DskipTests
  else 
    mvn package -DskipTests
  fi
  cp start.sh target/.
  mkdir ../compute/app
  cp -r target/* ../compute/app/.
elif [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
  docker image rm app:latest
  if [ "$TF_VAR_java_vm" == "graalvm_native" ]; then
    docker build -f Dockerfile.native -t app:latest . 
  else
    docker build -t app:latest . 
  fi  
fi  
