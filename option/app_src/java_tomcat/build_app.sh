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

mvn package

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  # Replace the user and password
  cp start.sh target/.
  cp install.sh target/.
  sed -i "s/##DB_USER##/$TF_VAR_db_user/" target/start.sh
  sed -i "s/##DB_PASSWORD##/$TF_VAR_db_password/" target/start.sh

  mkdir ../compute/app
  cp nginx_app.locations ../compute
  cp -r target/* ../compute/app/.

else
  docker image rm app:latest
  docker build -t app:latest .
fi  
