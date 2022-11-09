#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh

# Using RSYNC allow to reapply the same command several times easily
rsync -av -e "ssh -o StrictHostKeyChecking=no -i id_devops_rsa" db_src opc@$BASTION_IP:.
ssh -o StrictHostKeyChecking=no -i id_devops_rsa opc@$BASTION_IP "export DB_USER=\"$TF_VAR_db_user\";export DB_PASSWORD=\"$TF_VAR_db_password\";export DB_URL=\"$DB_URL\"; bash db_src/db_init.sh 2>&1 | tee -a db_src/db_init.log"

