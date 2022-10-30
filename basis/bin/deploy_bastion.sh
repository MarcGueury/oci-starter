#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/env_post_terraform.sh

# Using RSYNC allow to reapply the same command several times easily
rsync -Pav -e "ssh -o StrictHostKeyChecking=no -i id_devops_rsa" db_src opc@$BASTION_IP:db_src
ssh -o StrictHostKeyChecking=no -i id_devops_rsa opc@$BASTION_IP "export DB_USER=$TF_VAR_db_user;export DB_PASSWORD=$TF_VAR_db_password;export DB_URL=$TF_VAR_db_url; bash db_src/db_init.sh > db_src/db_init.log 2>&1"

