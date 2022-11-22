#!/bin/bash
# Build_app.sh
#
#!/bin/bash
# Parameter build or docker
# Compute:
# - build the code 
# - create a $ROOT/app directory with the compiled files
# - and a start.sh to start the program
# Docker:
# - build the image
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../bin/build_common.sh

# Replace the user and password in the configuration file (XXX)
CONFIG_FILE=src/start.sh
sed -i "s/##DB_USER##/$TF_VAR_db_user/" $CONFIG_FILE
sed -i "s/##DB_PASSWORD##/$TF_VAR_db_password/" $CONFIG_FILE

## XXXXX Check Python Version in env variables
if [ "$OCI_CLI_CLOUD_SHELL" == "true" ]; then
  echo 
fi

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  mkdir ../compute/app
  cp -r src/* ../compute/app/.
elif [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
  docker image rm app:latest
  docker build -t app:latest .
fi  
