#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../bin/build_common.sh

# Call build_common to push the app:latest and ui:latest to OCIR Docker registry
ocir_docker_push

echo "$DOCKER_PREFIX/ui:latest" > $TMP_DIR/docker_image_ui.txt
if [ ]; then 
  echo "$DOCKER_PREFIX/ui:latest" > $TMP_DIR/docker_image_app.txt
fi

cd $SCRIPT_DIR/..
. env.sh 
terraform/apply.sh --auto-approve