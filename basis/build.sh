#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Needed to get the TF_VAR_prefix
. variables.sh
. bin/sshkey_generate.sh
. bin/env_pre_terraform.sh
app_src/build_app.sh 
ui_src/build_ui.sh 
terraform/apply.sh --auto-approve

if [ -d oke ]; then
  . bin/env_post_terraform.sh
  oke/oke_deploy.sh
fi

bin/done.sh