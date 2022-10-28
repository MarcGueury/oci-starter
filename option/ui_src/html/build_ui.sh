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

if [ "$1" == "compute" ]; then
  mkdir ../compute/ui
  cp -r ui/* ../compute/ui/.
elif [ "$1" == "kubernetes" ]; then
  docker image rm ui:latest
  docker build -t ui:latest .
fi  
