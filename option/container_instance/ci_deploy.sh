#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../bin/build_common.sh

# Call build_common to push the ${TF_VAR_prefix}-app:latest and ui:latest to OCIR Docker registry
ocir_docker_push

echo "${DOCKER_PREFIX}/${TF_VAR_prefix}-ui:latest" > $TARGET_DIR/docker_image_ui.txt
if [ "$TF_VAR_language" != "ords" ]; then
  echo "${DOCKER_PREFIX}/${TF_VAR_prefix}-app:latest" > $TARGET_DIR/docker_image_app.txt
fi

cd $SCRIPT_DIR/..
. env.sh 
src/terraform/apply.sh --auto-approve