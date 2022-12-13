#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

# Using RSYNC allow to reapply the same command several times easily. 
if command -v rsync &> /dev/null
then
  rsync -av -e "ssh -o StrictHostKeyChecking=no -i target/ssh_key_starter" src/db opc@$BASTION_IP:.
else
  scp -r -o StrictHostKeyChecking=no -i target/ssh_key_starter src/db opc@$BASTION_IP:/home/opc/.
fi
ssh -o StrictHostKeyChecking=no -i target/ssh_key_starter opc@$BASTION_IP "export DB_USER=\"$TF_VAR_db_user\";export DB_PASSWORD=\"$TF_VAR_db_password\";export DB_URL=\"$DB_URL\"; bash db/db_init.sh 2>&1 | tee -a db/db_init.log"

