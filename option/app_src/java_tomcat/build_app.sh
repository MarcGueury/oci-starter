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
exit_on_error

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  # Replace the user and password
  cp start.sh target/.
  cp install.sh target/.
  replace_db_user_password_in_file target/start.sh

  mkdir ../compute/app
  cp nginx_app.locations ../compute
  cp -r target/* ../compute/app/.

else
  docker image rm app:latest
  docker build -t app:latest .
  exit_on_error
fi  
