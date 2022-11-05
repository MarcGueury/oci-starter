#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Needed to get the TF_VAR_prefix
. variables.sh
. bin/sshkey_generate.sh
. bin/auto_env.sh
terraform/apply.sh --auto-approve
. bin/auto_env.sh
bin/deploy_bastion.sh
app_src/build_app.sh 
ui_src/build_ui.sh 

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  bin/deploy_compute.sh
elif [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
  oke/oke_deploy.sh
fi

bin/done.sh