#!/bin/bash
# Build_ui.sh
#
# Parameter build or docker
# Compute:
# - build the code 
# - create a $ROOT/compute/ui directory with the compiled files
# - and a start.sh to start the program
# Docker:
# - build the image
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../bin/build_common.sh

if [ -d starter ]; then
  cd starter
  node_modules/grunt-cli/bin/grunt vb-clean
else
  mkdir starter
  cd starter
  unzip ../starter.zip
  npm install
fi    
node_modules/grunt-cli/bin/grunt vb-process-local
cd ..

mkdir -p ui
rm -Rf ui/*
cp -r starter/build/processed/webApps/starter/* ui/.

# Common
if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  mkdir -p ../compute/ui
  cp -r ui/* ../compute/ui/.
elif [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
  docker image rm ui:latest
  docker build -t ui:latest .
fi  
