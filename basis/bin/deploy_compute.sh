#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

scp -i ../id_devops_rsa compute opc@$COMPUTE_IP:.
ssh -i ../id_devops_rsa opc@$COMPUTE_IP "export TF_VAR_java_version=$TF_VAR_java_version;export TF_VAR_language=$TF_VAR_language;export JDBC_URL=$JDBC_URL;export DB_HOST=$DB_HOST;mv compute/* .;rmdir compute;bash compute_bootstrap.sh > compute_bootstrap.log 2>&1"
