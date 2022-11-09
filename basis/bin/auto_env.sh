#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# -- Functions --------------------------------------------------------------
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

# -- env.sh
if grep -q "__TO_FILL__" $SCRIPT_DIR/../env.sh; then
  echo "Error: missing environment variables."
  echo
  echo "Edit the file env.sh. Some variables needs to be filled:" 
  echo `cat env.sh | grep __TO_FILL__` 
  exit
fi
# . $SCRIPT_DIR/../env.sh

if ! command -v jq &> /dev/null; then
  echo "Command jq could not be found. Please install it"
  echo "Ex on linux: sudo yum install jq -y"
  exit 1
fi

#-- PRE terraform ----------------------------------------------------------
# XXXXXX -> Should detect when a new output is created
if [ -v STARTER_VARIABLES_SET ]; then
  echo "Variables already set"
else 
  export STARTER_VARIABLES_SET="PRE"

  if [ "$OCI_CLI_CLOUD_SHELL" == "True" ];  then
    # Cloud Shell
    export TF_VAR_tenancy_ocid=$OCI_TENANCY
    export TF_VAR_region=$OCI_REGION
  elif [ -f $HOME/.oci/config ]; then
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

  # Kubernetes and OCIR
  if [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
    export TF_VAR_namespace=`oci os ns get | jq -r .data`
    echo TF_VAR_namespace=$TF_VAR_namespace
    export TF_VAR_username=`oci iam user get --user-id $TF_VAR_user_ocid | jq -r '.data.name'`
    echo TF_VAR_username=$TF_VAR_username
    export TF_VAR_email=mail@domain.com
    echo TF_VAR_email=$TF_VAR_email
    export TF_VAR_ocir=${TF_VAR_region}.ocir.io
    echo TF_VAR_ocir=$TF_VAR_ocir
    
    export DOCKER_PREFIX=${TF_VAR_ocir}/${TF_VAR_namespace}
    echo DOCKER_PREFIX=$DOCKER_PREFIX
    export KUBECONFIG=$SCRIPT_DIR/../terraform/starter_kubeconfig
  fi
fi

#-- POST terraform ----------------------------------------------------------
export STATE_FILE=$SCRIPT_DIR/../terraform/terraform.tfstate
if [ -f $STATE_FILE ]; then
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
  get_output_from_tfstate "DB_URL" "db_url"

  if [ "$TF_VAR_db_strategy" == "autonomous" ]; then
    get_output_from_tfstate "ORDS_URL" "ords_url"
  fi

  if [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
    # OKE
    get_output_from_tfstate "OKE_OCID" "oke_ocid"
  fi
fi

