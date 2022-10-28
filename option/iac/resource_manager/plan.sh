#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
. ../bin/env_pre_terraform.sh

if[ ! -f ../tmp/resource_manager_stackid ]; then
   echo "Stack does exists already ( file ../tmp/resource_manager_stackid not found )"
   exit
fi    
source ../tmp/resource_manager_stackid

echo "Creating Plan Job"
CREATED_PLAN_JOB_ID=$(oci resource-manager job create-plan-job --stack-id $STACK_ID --wait-for-state SUCCEEDED --query 'data.id' --raw-output)
echo "Created Plan Job Id: ${CREATED_PLAN_JOB_ID}"

echo "Getting Job Logs"
echo $(oci resource-manager job get-job-logs --job-id $CREATED_PLAN_JOB_ID) 
