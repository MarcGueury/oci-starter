#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Build all
# Generate sshkeys if not part of a Common Resources project 
if [ ! -f ../group_common_env.sh ]; then
  . bin/sshkey_generate.sh
fi
. env.sh
# Run Terraform
src/terraform/apply.sh --auto-approve -no-color
exit_on_error

. env.sh
# Build the DB (via Bastion), the APP and the UI
if [ -d src/db ]; then
  bin/deploy_bastion.sh
fi  

# Init target/compute
if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
    mkdir -p target/compute
    cp src/compute/* target/compute/.
fi

if [ -f src/app/build_app.sh ]; then
    src/app/build_app.sh 
    exit_on_error
fi

if [ -f src/ui/build_ui.sh ]; then
    src/ui/build_ui.sh 
    exit_on_error
fi

# Deploy
if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
    bin/deploy_compute.sh
elif [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
    bin/oke_deploy.sh
elif [ "$TF_VAR_deploy_strategy" == "container_instance" ]; then
    bin/ci_deploy.sh
fi

bin/done.sh
