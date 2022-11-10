#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

export BUILDRUN_HASH=`echo ${OCI_BUILD_RUN_ID} | rev | cut -c 1-7`
echo "BUILDRUN_HASH: " $BUILDRUN_HASH

cd app
fn build  --verbose
echo "`docker images`"
docker tag function:1.0 app:1.0

# Output is a container 