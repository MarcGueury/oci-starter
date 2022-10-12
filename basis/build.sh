SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

. bin/sshkey_generate.sh
. bin/env_pre_terraform.sh
app_src/build_app.sh compute
ui_src/build_ui.sh compute
bin/terraform.sh


