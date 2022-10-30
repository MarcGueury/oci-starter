#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
. ../bin/env_pre_terraform.sh

set -e

TMP_DIR=../tmp
if [ ! -d $TMP_DIR ]; then
  mkdir $TMP_DIR
fi

resource_manager_get_stack() {
  if [ ! -f ../tmp/resource_manager_stackid ]; then
    echo "Stack does not exists ( file ../tmp/resource_manager_stackid not found )"
    exit
  fi    
  source ../tmp/resource_manager_stackid
}

rs_echo() {
  echo "Resource Manager: $1"
}

resource_manager_create() {
  rs_echo "Create Stack"

  if [ -f ../tmp/resource_manager_stackid ]; then
     echo "Stack exists already ( file ../tmp/resource_manager_stackid found )"
     return
  fi    

  ZIP_FILE_PATH=$TMP_DIR/resource_manager_$TF_VAR_prefix.zip
  if [ -f $ZIP_FILE_PATH ]; then
    rm $ZIP_FILE_PATH
  fi  
  zip -r $ZIP_FILE_PATH *

  # Transforms the variables in a JSON format
  # This is a complex way to get them. But it works for multi line variables like TF_VAR_private_key
  excluded=$(env | sed -n 's/^\([A-Z_a-z][0-9A-Z_a-z]*\)=.*/\1/p' | grep -v 'TF_VAR_')
  sh -c 'unset $1; export -p' sh "$excluded" > $TMP_DIR/tf_var.sh
  echo -n "{" > $TMP_DIR/variables.json
  cat $TMP_DIR/tf_var.sh | sed "s/export TF_VAR_/\"/g" | sed "s/=\"/\": \"/g" | sed ':a;N;$!ba;s/\"\n/\", /g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/$/}/'>> $TMP_DIR/variables.json

	STACK_ID=$(oci resource-manager stack create --compartment-id $TF_VAR_compartment_ocid --config-source $ZIP_FILE_PATH --display-name resource_manager_$TF_VAR_prefix  --variables file://$TMP_DIR/variables.json --query 'data.id' --raw-output)
  echo "Created stack id: ${STACK_ID}"
  echo "export STACK_ID=$STACK_ID" > $TMP_DIR/resource_manager_stackid
}

resource_manager_plan() {
  resource_manager_get_stack

  rs_echo "Create Plan Job"
  CREATED_PLAN_JOB_ID=$(oci resource-manager job create-plan-job --stack-id $STACK_ID --wait-for-state SUCCEEDED --wait-for-state FAILED --query 'data.id' --raw-output)
  echo "Created Plan Job Id: ${CREATED_PLAN_JOB_ID}"

  rs_echo "Get Job Logs"
  echo $(oci resource-manager job get-job-logs --job-id $CREATED_PLAN_JOB_ID) > $TMP_DIR/plan_job_logs.txt
  echo "Saved Job Logs"
}

resource_manager_apply() {
  resource_manager_get_stack 

  rs_echo "Create Apply Job"
  CREATED_APPLY_JOB_ID=$(oci resource-manager job create-apply-job --stack-id $STACK_ID --execution-plan-strategy=AUTO_APPROVED --wait-for-state SUCCEEDED --wait-for-state FAILED --query 'data.id' --raw-output)
  echo "Created Apply Job Id: ${CREATED_APPLY_JOB_ID}"

  rs_echo "Get job"
  STATUS=$(oci resource-manager job get --job-id $CREATED_APPLY_JOB_ID  --query 'data."lifecycle-state"' --raw-output)
 
  rs_echo "Get stack state"
  # XXXXX terraform state will be zipped in a next run
  oci resource-manager stack get-stack-tf-state --stack-id $STACK_ID --file terraform.tfstate
}

resource_manager_destroy() {
  resource_manager_get_stack 
  
  rs_echo "Create Destroy Job"
  CREATED_DESTROY_JOB_ID=$(oci resource-manager job create-destroy-job --stack-id $STACK_ID --execution-plan-strategy=AUTO_APPROVED --wait-for-state SUCCEEDED --query 'data.id' --raw-output)
  echo "Created Destroy Job Id: ${CREATED_DESTROY_JOB_ID}"

  rs_echo "Get job"
  STATUS=$(oci resource-manager job get --job-id $CREATED_DESTROY_JOB_ID  --query 'data."lifecycle-state"' --raw-output)
 
  # XXXX Check the result of the destroy JOB and stop deletion if required
  if [ "$STATUS" != "SUCCEEDED" ]; then
    echo "ERROR. Exiting"
  fi  

  rs_echo "Delete Stack"
  oci resource-manager stack delete --stack-id $STACK_ID --force
  echo "Deleted Stack Id: ${STACK_ID}"
  rm $TMP_DIR/resource_manager_stackid
}

# echo "Creating Import Tf State Job"
# CREATED_IMPORT_JOB_ID=$(oci resource-manager job create-import-tf-state-job --stack-id $STACK_ID --tf-state-file "$JOB_TF_STATE" --wait-for-state SUCCEEDED --query 'data.id' --raw-output)
# echo "Created Import Tf State Job Id: ${CREATED_IMPORT_JOB_ID}"
