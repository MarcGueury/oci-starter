#!/bin/bash
. bin/env_pre_terraform.sh

cd terraform
terraform destroy
cd ..