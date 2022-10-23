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
if [ $1 != "compute" ] && [ $1 != "kubernetes" ] ; then
  echo 'Argument required: build or kubernetes'
  exit
fi

if [ $1 == "compute" ]; then
  mkdir ../compute/ui
  cp -r ui/* ../compute/ui/.
elif [ $1 == "kubernetes" ]; then
  docker image rm ui:latest
  docker build -t ui:latest .
fi  

Notes:
...
  sudo yum install -y oracle-nodejs-release-el7 oracle-release-el7
  sudo yum install -y nodejs
  cd vb
  npm install
  sudo npm install -g grunt
  npm install
  grunt vb-process-local vb-package  
  grunt vb-serve --port=7070
...
Serving web application from "build/optimized/webApps/starter" directory at "http://localhost:7070/"

sudo rm -Rf  /usr/share/nginx/html/starter
sudo cp -r build/optimized/webApps/starter /usr/share/nginx/html/.

-> It works !
...  