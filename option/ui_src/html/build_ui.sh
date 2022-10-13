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
cd $SCRIPT_DIR
if [ $1 != "compute" ] && [ $1 != "docker" ] ; then
  echo 'Argument required: build or docker'
  exit
fi

if [ $1 == "compute" ]; then
  mkdir ../compute/ui
  cp -r ui/* ../compute/ui/.
elif [ $1 == "docker" ]; then
  docker build -t XXXX
fi  
