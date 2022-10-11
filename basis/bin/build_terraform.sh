SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

. bin/sshkey_generate.sh
. bin/env_pre_terraform.sh
. bin/terraform.sh
# . bin/env_post_terraform.sh
