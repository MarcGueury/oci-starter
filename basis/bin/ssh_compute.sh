#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/auto_env.sh
cd $SCRIPT_DIR/..
ssh opc@$COMPUTE_IP -i id_devops_rsa

