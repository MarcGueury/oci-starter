#!/bin/bash
. ../bin/env_pre_terraform.sh
terraform apply "$@"
