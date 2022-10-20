#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Call the script with --auto-approve to destroy without prompt

. bin/env_pre_terraform.sh
if [ -d oke ]; then
  oke/oke_destroy.sh $1
fi

cd terraform
terraform destroy $1
cd ..