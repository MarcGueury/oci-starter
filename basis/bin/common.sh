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
    mkdir -p ../../target/compute/ui
    cp -r ui/* ../../target/compute/ui/.
  elif [ "$TF_VAR_deploy_strategy" == "function" ]; then 
    oci os object bulk-upload -ns $TF_VAR_namespace -bn ${TF_VAR_prefix}-public-bucket --src-dir ui --overwrite --content-type auto
  else
    # Kubernetes and Container Instances
    docker image rm ui:latest
    docker build -t ui:latest .
  fi 
}

build_function() {
  # Build the function
  fn create context ${TF_VAR_region} --provider oracle
  fn use context ${TF_VAR_region}
  fn update context oracle.compartment-id ${TF_VAR_compartment_ocid}
  fn update context api-url https://functions.${TF_VAR_region}.oraclecloud.com
  fn update context registry ${TF_VAR_ocir}/${TF_VAR_namespace}
  fn build -v | tee $TARGET_DIR/fn_build.log
  if grep --quiet "built successfully" $TARGET_DIR/fn_build.log; then
     fn bump
     # Store the image name and DB_URL in files
     grep "built successfully" $TARGET_DIR/fn_build.log | sed "s/Function //" | sed "s/ built successfully.//" > $TARGET_DIR/fn_image.txt
     echo "$1" > $TARGET_DIR/fn_db_url.txt
     . ../../env.sh
     # Push the image to docker
     docker login ${TF_VAR_ocir} -u ${TF_VAR_namespace}/${TF_VAR_username} -p "${TF_VAR_auth_token}"
     docker push $TF_VAR_fn_image
  fi 

  # First create the Function using terraform
  # Run env.sh to get function image 
  cd $ROOT_DIR
  . env.sh 
  src/terraform/apply.sh --auto-approve
}

ocir_docker_push () {
  # Docker Login
  docker login ${TF_VAR_ocir} -u ${TF_VAR_namespace}/${TF_VAR_username} -p "${TF_VAR_auth_token}"
  echo DOCKER_PREFIX=$DOCKER_PREFIX

  # Push image in registry
  docker tag app $DOCKER_PREFIX/app:latest
  docker push $DOCKER_PREFIX/app:latest

  docker tag ui $DOCKER_PREFIX/ui:latest
  docker push $DOCKER_PREFIX/ui:latest
}

replace_db_user_password_in_file() {
  # Replace DB_USER DB_PASSWORD
  CONFIG_FILE=$1
  sed -i "s/##DB_USER##/$TF_VAR_db_user/" $CONFIG_FILE
  sed -i "s/##DB_PASSWORD##/$TF_VAR_db_password/" $CONFIG_FILE
}  

exit_on_error() {
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    echo "Success"
  else
    echo "Failed (RESULT=$RESULT)"
    exit $RESULT
  fi  
}

auto_echo () {
  if [ -z "$SILENT_MODE" ]; then
    echo "$1"
  fi  
}

set_if_not_null () {
  if [ "$2" != "" ] && [ "$2" != "null" ]; then
    auto_echo "$1=$RESULT"
    export $1="$RESULT"
  fi  
}

get_attribute_from_tfstate () {
  RESULT=`jq -r '.resources[] | select(.name=="'$2'") | .instances[0].attributes.'$3'' $STATE_FILE`
  set_if_not_null $1 $RESULT
}

get_output_from_tfstate () {
  RESULT=`jq -r '.outputs."'$2'".value' $STATE_FILE | sed "s/ //"`
  set_if_not_null $1 $RESULT
}

