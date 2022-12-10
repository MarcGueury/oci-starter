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

# Replace the user and password in the start file
replace_db_user_password_in_file src/start.sh

## XXXXX Check Node Version in env variables
if [ "$OCI_CLI_CLOUD_SHELL" == "true" ]; then
  echo 
fi

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  mkdir ../compute/app
  cp -r src/* ../compute/app/.
else
  docker image rm app:latest
  docker build -t app:latest .
  exit_on_error
fi  
