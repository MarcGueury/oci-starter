#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Variables
. $SCRIPT_DIR/../variables.sh

cd $SCRIPT_DIR/..

if [ -f terraform/terraform.tfstate ]; then
  export STATE_FILE=terraform/terraform.tfstate
else
  oci os object get -bn ${TF_VAR_prefix}-terraform --name tfstate.tf --file /tmp/tfstate.tf
  export STATE_FILE=/tmp/tfstate.tf
fi

get_attribute_from_tfstate () {
  RESULT=`jq -r '.resources[] | select(.name=="'$2'") | .instances[0].attributes.'$3'' $STATE_FILE`
  echo "$1=$RESULT"
  export $1="$RESULT"
}

get_output_from_tfstate () {
  RESULT=`jq -r '.outputs."'$2'".value' $STATE_FILE | sed "s/ //"`
  echo "$1=$RESULT"
  export $1="$RESULT"
}

# OBJECT_STORAGE_URL
export OBJECT_STORAGE_URL=https://objectstorage.${TF_VAR_region}.oraclecloud.com

# Functions
if [ "$TF_VAR_deploy_strategy" == "function" ]; then
  # APIGW URL
  get_attribute_from_tfstate "APIGW_HOSTNAME" "${TF_VAR_prefix}_apigw" "hostname"

  # Function URL
  get_attribute_from_tfstate "FUNCTION_ENDPOINT" "function" "invoke_endpoint"
  get_attribute_from_tfstate "FUNCTION_ID" "function" "id"
  export FUNCTION_URL=$FUNCTION_ENDPOINT/20181201/functions/$FUNCTION_ID
fi

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  get_attribute_from_tfstate "COMPUTE_IP" "starter_instance" "public_ip"
fi

# Bastion 
get_attribute_from_tfstate "BASTION_IP" "starter_bastion" "public_ip"

# JDBC_URL
get_output_from_tfstate "JDBC_URL" "jdbc_url"
