#!/bin/bash
# OCI Starter
# 
# Script to create a directory or a zip file with the source code
# 
# Author: Marc Gueury
# Date: 2022-10-15
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

title() {
    TITLE="-- $1 ---------------------------------------------------------------------"
    echo ${TITLE:0:78} 
}

title oci_starter.sh 

# keeping this section here so that $MODE etc. are accessible after py_oci_starter.py has run
# if [ "$#" -eq 3 ]; then
#   export MODE=GIT
#   export GIT_URL=$1
#   export REPOSITORY_NAME=$2
#   export OCI_USERNAME=$3
#   echo GIT_URL=$GIT_URL
# else
#   export MODE=CLI
# fi

rm -rf ./output 
python3 py_oci_starter.py "$@"
