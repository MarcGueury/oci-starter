#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../bin/build_common.sh

# Cloud Shell
fn create context ${TF_VAR_region} --provider oracle
fn use context ${TF_VAR_region}
fn update context oracle.compartment-id ${TF_VAR_compartment_ocid}
fn update context api-url https://functions.${TF_VAR_region}.oraclecloud.com
fn update context registry ${TF_VAR_ocir}/${TF_VAR_namespace}
fn build --verbose | tee > $TMP_DIR/fn_build.log
if grep --quiet "built successfully" $TMP_DIR/fn_build.log; then
   grep "built successfully" $TMP_DIR/fn_build.log | sed "s/Function //" | sed "s/ built successfully.//" > $TMP_DIR/fn_image.txt
   echo "$JDBC_URL" > $TMP_DIR/fn_db_url.txt
   . ../env.sh
   docker login ${TF_VAR_ocir} -u ${TF_VAR_namespace}/${TF_VAR_username} -p "${TF_VAR_auth_token}"
   docker push $TF_VAR_fn_image
fi 
# fn -v deploy --app ${TF_VAR_prefix}-fn-application
# fn invoke ${TF_VAR_prefix}-fn-application ${TF_VAR_prefix}-fn-function
# fn config function ${TF_VAR_prefix}-fn-application fn-starter DB_USER $TF_VAR_db_user
# fn config function ${TF_VAR_prefix}-fn-application fn-starter DB_PASSWORD $TF_VAR_db_password
# fn config function ${TF_VAR_prefix}-fn-application fn-starter DB_URL $JDBC_URL
# Function eu-frankfurt-1.ocir.io/frsxwtjslf35/fn-starter:0.0.30 built successfully.

# Deploy with terraform
# Then Work-around: terraforms is not able to create a APIGW with dynamic multiple backends
build_function

