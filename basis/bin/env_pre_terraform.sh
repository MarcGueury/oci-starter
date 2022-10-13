#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Variables
. $SCRIPT_DIR/../variables.sh

if ! command -v jq &> /dev/null
then
    echo "Command jq could not be found. Please install it"
    echo "Ex on linux: sudo yum install jq -y"
    exit
fi

if [ $OCI_CLI_CLOUD_SHELL=="True" ];  then
  export TF_VAR_tenancy_ocid=$OCI_TENANCY
  export TF_VAR_region=$OCI_REGION
fi 

# Get config from file
if [ -f $HOME/.oci/config ]; then
  ## Get the [DEFAULT] config
  sed -n -e '/\[DEFAULT\]/,$p' $HOME/.oci/config > /tmp/ociconfig
  export TF_VAR_user_ocid=`sed -n 's/user=//p' /tmp/ociconfig |head -1`
  export TF_VAR_fingerprint=`sed -n 's/fingerprint=//p' /tmp/ociconfig |head -1`
  export TF_VAR_private_key_path=`sed -n 's/key_file=//p' /tmp/ociconfig |head -1`
  export TF_VAR_region=`sed -n 's/region=//p' /tmp/ociconfig |head -1`
  export TF_VAR_tenancy_ocid=`sed -n 's/tenancy=//p' /tmp/ociconfig |head -1`  
  # echo TF_VAR_user_ocid=$TF_VAR_user_ocid
  # echo TF_VAR_fingerprint=$TF_VAR_fingerprint
  # echo TF_VAR_private_key_path=$TF_VAR_private_key_path
fi

if [ -z "$TF_VAR_compartment_ocid" ]; then
  echo "WARNING: compartment_ocid is not defined."
  echo "         The components will be created in the root compartment."
  export TF_VAR_compartment_ocid=$TF_VAR_tenancy_ocid
fi

# Namespace
export TF_VAR_ssh_public_key=$(cat $SCRIPT_DIR/../id_devops_rsa.pub)
export TF_VAR_ssh_private_key=$(cat $SCRIPT_DIR/../id_devops_rsa)
export TF_VAR_compartment_name=`oci iam compartment get --compartment-id=$TF_VAR_compartment_ocid | jq -r .data.name`

# Echo
echo TF_VAR_tenancy_ocid=$TF_VAR_tenancy_ocid
echo TF_VAR_compartment_ocid=$TF_VAR_compartment_ocid
echo TF_VAR_compartment_name=$TF_VAR_compartment_name
echo TF_VAR_region=$TF_VAR_region


