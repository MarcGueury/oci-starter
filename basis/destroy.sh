#!/bin/bash
# The first parameter is passed to terraform destroy to allow to use --auto-approve
. bin/env_pre_terraform.sh

cd terraform
terraform destroy $1
cd ..