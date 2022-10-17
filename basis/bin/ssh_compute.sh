#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/env_post_terraform.sh
ssh opc@$COMPUTE_IP -i id_devops_rsa

