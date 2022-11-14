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
  # Build the function
  fn create context ${TF_VAR_region} --provider oracle
  fn use context ${TF_VAR_region}
  fn update context oracle.compartment-id ${TF_VAR_compartment_ocid}
  fn update context api-url https://functions.${TF_VAR_region}.oraclecloud.com
  fn update context registry ${TF_VAR_ocir}/${TF_VAR_namespace}
  fn build --verbose | tee > $TMP_DIR/fn_build.log
  if grep --quiet "built successfully" $TMP_DIR/fn_build.log; then
     fn bump
     # Store the image name and DB_URL in files
     grep "built successfully" $TMP_DIR/fn_build.log | sed "s/Function //" | sed "s/ built successfully.//" > $TMP_DIR/fn_image.txt
     echo "$1" > $TMP_DIR/fn_db_url.txt
     . ../env.sh
     # Push the image to docker
     docker login ${TF_VAR_ocir} -u ${TF_VAR_namespace}/${TF_VAR_username} -p "${TF_VAR_auth_token}"
     docker push $TF_VAR_fn_image
  fi 

  # First create the Function using terraform
  # Run env.sh to get function image 
  cd $SCRIPT_DIR/..
  . env.sh
  terraform/apply.sh --auto-approve
}


# SCRIPT_DIR should be set by the calling scripts 
cd $SCRIPT_DIR
if [ ! -v TF_VAR_deploy_strategy ]; then
  echo 'Environment variables not set. Before to run the script, please run:'
  echo '. env.sh'
  exit
fi  
