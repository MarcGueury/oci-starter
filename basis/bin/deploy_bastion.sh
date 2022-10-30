#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

scp -i ../id_devops_rsa * opc@$BASTION_IP:db_src
ssh -i ../id_devops_rsa opc@$BASTION_IP "export DB_USER=$TF_VAR_db_user;export DB_PASSWORD=$TF_VAR_db_password;export DB_URL=$TF_VAR_db_url; bash db_src/db_init.sh > db_src/db_init.log 2>&1"
