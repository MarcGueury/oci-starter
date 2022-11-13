# Build_common.sh
# This file contains the common functions used by build_app.sh and build_ui.sh

### Commmon functions
# Check java version
check_java_version() {
    if [ "$OCI_CLI_CLOUD_SHELL" == "true" ]; then
    ## XX Check Java Version in env variables
    export JAVA_ID=`csruntimectl java list | grep jdk-17 | sed -e 's/^.*\(graal[^ ]*\) .*$/\1/'`
    csruntimectl java set $JAVA_ID
    fi
}

build_ui() {
  cd $SCRIPT_DIR
  if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
    mkdir -p ../compute/ui
    cp -r ui/* ../compute/ui/.
  elif [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
    docker image rm ui:latest
    docker build -t ui:latest .
  elif [ "$TF_VAR_deploy_strategy" == "function" ]; then 
    oci os object bulk-upload -ns $TF_VAR_namespace -bn ${TF_VAR_prefix}-public-bucket --src-dir ui --overwrite --content-type auto
  fi 
}

build_function() {
  # First create the Function using terraform
  # Run env.sh to get function image 
  cd $SCRIPT_DIR/..
  . env.sh
  terraform/apply.sh --auto-approve
  # Run env.sh to get function ocid 
  . env.sh
  # Apply the WA for APIGW Multiple Backend
  cp app_src/apigw_deployment.json $TMP_DIR/.
  sed -i "s&##BUCKET_URL##&${BUCKET_URL}&" $TMP_DIR/apigw_deployment.json
  sed -i "s&##FN_FUNCTION_OCID##&${FN_FUNCTION_OCID}&" $TMP_DIR/apigw_deployment.json
  oci api-gateway deployment update --force --deployment-id $APIGW_DEPLOYMENT_OCID --from-json file://$TMP_DIR/apigw_deployment.json
}


# SCRIPT_DIR should be set by the calling scripts 
cd $SCRIPT_DIR
if [ ! -v TF_VAR_deploy_strategy ]; then
  echo 'Environment variables not set. Before to run the script, please run:'
  echo '. env.sh'
  exit
fi  
