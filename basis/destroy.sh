#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Call the script with --auto-approve to destroy without prompt

echo "WARNING"
echo 
echo "This will destroy all the resources created by Terraform."
echo 
if [ "$1" != "--auto-approve" ]; then
  read -p "Do you want to proceed? (yes/no) " yn

  case $yn in 
  	yes ) echo Deleting;;
	no ) echo Exiting...;
		exit;;
	* ) echo Invalid response;
		exit 1;;
  esac
fi

. bin/env_pre_terraform.sh
if [ -d oke ]; then
  oke/oke_destroy.sh --auto-approve
fi

terraform/destroy.sh --auto-approve
