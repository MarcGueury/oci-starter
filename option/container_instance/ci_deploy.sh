#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../bin/build_common.sh

# Call build_common to push the app:latest and ui:latest to OCIR Docker registry
ocir_docker_push()