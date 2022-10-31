#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/env_post_terraform.sh

# Using RSYNC allow to reapply the same command several times easily
rsync -av -e "ssh -o StrictHostKeyChecking=no -i id_devops_rsa" compute/* opc@$COMPUTE_IP:.
ssh -o StrictHostKeyChecking=no -i id_devops_rsa opc@$COMPUTE_IP "export TF_VAR_java_version=\"$TF_VAR_java_version\";export TF_VAR_language=\"$TF_VAR_language\";export JDBC_URL=\"$JDBC_URL\";export DB_URL=\"$DB_URL\";bash compute_bootstrap.sh > compute_bootstrap.log 2>&1"
