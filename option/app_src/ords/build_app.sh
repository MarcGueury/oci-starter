#!/bin/bash
# Build_app.sh
#
#!/bin/bash
# Parameter build or docker
# Compute:
# - build the code 
# - create a $ROOT/app directory with the compiled files
# - and a start.sh to start the program
# Docker:
# - build the image
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../bin/build_common.sh

# Replace the ORDS URL
sed -i "s&##ORDS_URL##&$ORDS_URL&" nginx_app.conf
sed -i "s&##ORDS_URL##&$ORDS_URL&" ingress-app.yaml

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  cp nginx_app.conf ../compute
elif [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
  echo "No docker image needed"
fi  
