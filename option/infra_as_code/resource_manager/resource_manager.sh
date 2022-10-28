#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
. ../bin/env_pre_terraform.sh

set -e

WORKING_DIR=../tmp
if [ ! -d $WORKING_DIR ]; then
  mkdir ../tmp
fi


resource_manager_get_stack() {
  if[ ! -f ../tmp/resource_manager_stackid ]; then
    echo "Stack does exists already ( file ../tmp/resource_manager_stackid not found )"
    exit
  fi    
  source ../tmp/resource_manager_stackid
}


resource_manager_create() {
  echo "Creating Stack"

  if[ -f ../tmp/resource_manager_stackid ]; then
     echo "Stack exists already ( file ../tmp/resource_manager_stackid found )"
     exit
  fi    

  ZIP_FILE_PATH=$WORKING_DIR/resource_manager_$TF_VAR_prefix.zip
  rm $ZIP_FILE_PATH
  zip -r $ZIP_FILE_PATH *

  if [ "${WORKING_DIR}" == "" ]; then
    STACK_ID=$(oci resource-manager stack create --compartment-id $COMPARTMENT_ID --config-source $ZIP_FILE_PATH --query 'data.id' --raw-output)
  else
  	STACK_ID=$(oci resource-manager stack create --compartment-id $COMPARTMENT_ID --config-source $ZIP_FILE_PATH --working-directory $WORKING_DIR --query 'data.id' --raw-output)
  fi
  echo "Created stack id: ${STACK_ID}"
  echo "export STACK_ID=$STACK_ID" > ../tmp/resource_manager_stackid
}

resource_manager_plan() {
  resource_manager_get_stack

  echo "Creating Plan Job"
  CREATED_PLAN_JOB_ID=$(oci resource-manager job create-plan-job --stack-id $STACK_ID --wait-for-state SUCCEEDED --query 'data.id' --raw-output)
  echo "Created Plan Job Id: ${CREATED_PLAN_JOB_ID}"

  echo "Getting Job Logs"
  echo $(oci resource-manager job get-job-logs --job-id $CREATED_PLAN_JOB_ID) > $WORKING_DIR/plan_job_logs.txt
  echo "Saved Job Logs"
}

resource_manager_apply() {
  resource_manager_get_stack

  echo "Creating Apply Job"
  CREATED_APPLY_JOB_ID=$(oci resource-manager job create-apply-job --stack-id $STACK_ID --execution-plan-strategy FROM_PLAN_JOB_ID --execution-plan-job-id "$CREATED_PLAN_JOB_ID" --wait-for-state SUCCEEDED --query 'data.id' --raw-output)
  echo "Created Apply Job Id: ${CREATED_APPLY_JOB_ID}"

  echo "Getting Job Terraform state"
  oci resource-manager job get-job-tf-state --job-id $CREATED_APPLY_JOB_ID --file $WORKING_DIR/job_tf_state.txt
  echo "Saved Job TF State"
}

resource_manager_destroy() {
  resource_manager_get_stack 
  
  echo "Creating Destroy Job"
  CREATED_DESTROY_JOB_ID=$(oci resource-manager job create-destroy-job --stack-id $STACK_ID --execution-plan-strategy=AUTO_APPROVED --wait-for-state SUCCEEDED --query 'data.id' --raw-output)
  echo "Created Destroy Job Id: ${CREATED_DESTROY_JOB_ID}"

  echo "Deleting Stack"
  oci resource-manager stack delete --stack-id $STACK_ID --force
  echo "Deleted Stack Id: ${STACK_ID}"
}

# echo "Creating Import Tf State Job"
# CREATED_IMPORT_JOB_ID=$(oci resource-manager job create-import-tf-state-job --stack-id $STACK_ID --tf-state-file "$JOB_TF_STATE" --wait-for-state SUCCEEDED --query 'data.id' --raw-output)
# echo "Created Import Tf State Job Id: ${CREATED_IMPORT_JOB_ID}"
