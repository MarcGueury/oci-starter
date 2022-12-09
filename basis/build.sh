#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Build all
. bin/sshkey_generate.sh
. env.sh
# Run Terraform
. terraform/apply.sh --auto-approve
. env.sh
# Build the DB (via Bastion), the APP and the UI
bin/deploy_bastion.sh
app_src/build_app.sh 
ui_src/build_ui.sh 

# Deploy
if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  bin/deploy_compute.sh
elif [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
  oke/oke_deploy.sh
elif [ "$TF_VAR_deploy_strategy" == "container_instance" ]; then
  container_instance/ci_deploy.sh
fi

bin/done.sh

