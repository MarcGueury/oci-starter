#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Build all
. bin/sshkey_generate.sh
. env.sh
# Run Terraform
src/terraform/apply.sh --auto-approve
exit_on_error

. env.sh
# Build the DB (via Bastion), the APP and the UI
bin/deploy_bastion.sh

# Init target/compute
if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  mkdir -p target/compute
  cp src/compute/* target/compute/.
fi

src/app/build_app.sh 
exit_on_error

src/ui/build_ui.sh 
exit_on_error

# Deploy
if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  bin/deploy_compute.sh
elif [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
  bin/oke_deploy.sh
elif [ "$TF_VAR_deploy_strategy" == "container_instance" ]; then
  bin/ci_deploy.sh
fi

bin/done.sh
