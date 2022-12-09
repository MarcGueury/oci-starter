#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# -- Functions --------------------------------------------------------------
auto_echo () {
  if [ -z "$SILENT_MODE" ]; then
    echo "$1"
  fi  
}

get_attribute_from_tfstate () {
  RESULT=`jq -r '.resources[] | select(.name=="'$2'") | .instances[0].attributes.'$3'' $STATE_FILE`
  auto_echo "$1=$RESULT"
  export $1="$RESULT"
}

get_output_from_tfstate () {
  RESULT=`jq -r '.outputs."'$2'".value' $STATE_FILE | sed "s/ //"`
  auto_echo "$1=$RESULT"
  export $1="$RESULT"
}

exit_on_error() {
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    echo "Success"
  else
    echo "Failed"
    exit $RESULT
  fi  
}

# Silent mode (default is not silent)
if [ "$1" == "-silent" ]; then
  SILENT_MODE=true
else
  unset SILENT_MODE
fi 

if [ "$TF_VAR_db_password" == "__TO_FILL__" ]; then
  echo "Generating password for the database"
  export TF_VAR_db_password=`python3 $SCRIPT_DIR/gen_password.py`
  sed -i "s&TF_VAR_db_password=\"__TO_FILL__\"&TF_VAR_db_password=\"$TF_VAR_db_password\"&" $SCRIPT_DIR/../env.sh
  echo "Password stored in env.sh"
  echo "> TF_VAR_db_password=$TF_VAR_db_password"
fi

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

export TMP_DIR=$SCRIPT_DIR/../tmp
if [ ! -d $TMP_DIR ]; then
  mkdir $TMP_DIR
fi

#-- PRE terraform ----------------------------------------------------------
if [ "$OCI_STARTER_VARIABLES_SET" == "$OCI_STARTER_CREATION_DATE" ]; then
  echo "Variables already set"
else 
  export OCI_STARTER_VARIABLES_SET=$OCI_STARTER_VARIABLES_SET


  if [ "$OCI_CLI_CLOUD_SHELL" == "True" ];  then
    # Cloud Shell
    export TF_VAR_tenancy_ocid=$OCI_TENANCY
    export TF_VAR_region=$OCI_REGION
    if [[ "$OCI_CS_USER_OCID" == *"ocid1.saml2idp"* ]]; then
      # Ex: ocid1.saml2idp.oc1..aaaaaaaaexfmggau73773/user@domain.com -> oracleidentitycloudservice/user@domain.com
      # Split the string in 2 
      IFS='/' read -r -a array <<< "$OCI_CS_USER_OCID"
      IDP_NAME=`oci iam identity-provider get --identity-provider-id=${array[0]} | jq -r .data.name`
      IDP_NAME_LOWER=${IDP_NAME,,}
      export TF_VAR_username="$IDP_NAME_LOWER/${array[1]}"
    else 
      export TF_VAR_username=$OCI_CS_USER_OCID
    fi
  elif [ -f $HOME/.oci/config ]; then
    ## Get the [DEFAULT] config
    if [ -z "$OCI_CLI_PROFILE" ]; then
      OCI_PRO=DEFAULT
    else 
      OCI_PRO=$OCI_CLI_PROFILE
    fi    
    sed -n -e "/\[$OCI_PRO\]/,$$p" $HOME/.oci/config > /tmp/ociconfig
    export TF_VAR_user_ocid=`sed -n 's/user=//p' /tmp/ociconfig |head -1`
    export TF_VAR_fingerprint=`sed -n 's/fingerprint=//p' /tmp/ociconfig |head -1`
    export TF_VAR_private_key_path=`sed -n 's/key_file=//p' /tmp/ociconfig |head -1`
    export TF_VAR_region=`sed -n 's/region=//p' /tmp/ociconfig |head -1`
    export TF_VAR_tenancy_ocid=`sed -n 's/tenancy=//p' /tmp/ociconfig |head -1`  
    # echo TF_VAR_user_ocid=$TF_VAR_user_ocid
    # echo TF_VAR_fingerprint=$TF_VAR_fingerprint
    # echo TF_VAR_private_key_path=$TF_VAR_private_key_path
  fi

  # SSH keys
  export TF_VAR_ssh_public_key=$(cat $SCRIPT_DIR/../id_starter_rsa.pub)
  export TF_VAR_ssh_private_key=$(cat $SCRIPT_DIR/../id_starter_rsa)


  if [ -z "$TF_VAR_compartment_ocid" ]; then
    echo "WARNING: compartment_ocid is not defined."
    # echo "        The components will be created in the root compartment."
    # export TF_VAR_compartment_ocid=$TF_VAR_tenancy_ocid

    echo "         The components will be created in the 'oci-starter' compartment"
    STARTER_OCID=`oci iam compartment list --name oci-starter | jq .data[0].id -r`
    if [ -z "$STARTER_OCID" ]; then
      echo "Creating a new 'oci-starter' compartment"
      oci iam compartment create --compartment-id $TF_VAR_tenancy_ocid --description oci-starter --name oci-starter --wait-for-state ACTIVE > $TMP_DIR/compartment.log 2>&1
      STARTER_OCID=`cat $TMP_DIR/compartment.log | grep \"id\" | sed 's/"//g' | sed "s/.*id: //g" | sed "s/,//g"`
      while [ "$NAME" != "oci-starter" ]
      do
        oci iam compartment get --compartment-id=$STARTER_OCID > $TMP_DIR/waiting.log 2>&1
        if grep -q "NotAuthorizedOrNotFound" $TMP_DIR/waiting.log; then
          echo "Waiting"
          sleep 2
        else
          NAME=`cat $TMP_DIR/waiting.log | jq -r .data.name`
        fi
      done
    else
      echo "Using the existing 'oci-starter' Compartment"
    fi 
    export TF_VAR_compartment_ocid=$STARTER_OCID
    auto_echo "TF_VAR_compartment_ocid=$STARTER_OCID"
    echo "Compartment created"
  fi

  # Echo
  auto_echo TF_VAR_tenancy_ocid=$TF_VAR_tenancy_ocid
  auto_echo TF_VAR_compartment_ocid=$TF_VAR_compartment_ocid
  auto_echo TF_VAR_region=$TF_VAR_region

  # Kubernetes and OCIR
  if [ "$TF_VAR_deploy_strategy" == "kubernetes" ] || [ "$TF_VAR_deploy_strategy" == "function" ] || [ "$TF_VAR_deploy_strategy" == "container_instance" ]; then
    export TF_VAR_namespace=`oci os ns get | jq -r .data`
    auto_echo TF_VAR_namespace=$TF_VAR_namespace
    # Find TF_VAR_username based on TF_VAR_user_ocid or the opposite
    if [ "$TF_VAR_username" != "" ]; then
      export TF_VAR_user_ocid=`oci iam user list --name $TF_VAR_username | jq -r .data[0].id`
    elif [ "$TF_VAR_user_ocid" != "" ]; then
      export TF_VAR_username=`oci iam user get --user-id $TF_VAR_user_ocid | jq -r '.data.name'`
    fi  
    auto_echo TF_VAR_username=$TF_VAR_username
    export TF_VAR_email=mail@domain.com
    auto_echo TF_VAR_email=$TF_VAR_email
    export TF_VAR_ocir=${TF_VAR_region}.ocir.io
    auto_echo TF_VAR_ocir=$TF_VAR_ocir
    
    export DOCKER_PREFIX=${TF_VAR_ocir}/${TF_VAR_namespace}
    auto_echo DOCKER_PREFIX=$DOCKER_PREFIX
    export KUBECONFIG=$SCRIPT_DIR/../terraform/starter_kubeconfig
  fi
fi

#-- POST terraform ----------------------------------------------------------
export STATE_FILE=$SCRIPT_DIR/../terraform/terraform.tfstate
if [ -f $STATE_FILE ]; then
  # OBJECT_STORAGE_URL
  export OBJECT_STORAGE_URL=https://objectstorage.${TF_VAR_region}.oraclecloud.com

  # API GW
  if [ "$TF_VAR_deploy_strategy" == "function" ] || [ "$TF_VAR_deploy_strategy" == "container_instance" ]; then
    # APIGW URL
    get_attribute_from_tfstate "APIGW_HOSTNAME" "starter_apigw" "hostname"
    # APIGW Deployment id
    get_attribute_from_tfstate "APIGW_DEPLOYMENT_OCID" "starter_apigw_deployment" "id"
  fi

  # Functions
  if [ "$TF_VAR_deploy_strategy" == "function" ]; then
    # OBJECT Storage URL
    export BUCKET_URL="https://objectstorage.${TF_VAR_region}.oraclecloud.com/n/${TF_VAR_namespace}/b/${TF_VAR_prefix}-public-bucket/o"

    # Function OCID
    get_attribute_from_tfstate "FN_FUNCTION_OCID" "starter_fn_function" "id"

    auto_echo "file=$TMP_DIR/fn_image.txt" 
    if [ -f $TMP_DIR/fn_image.txt ]; then
      export TF_VAR_fn_image=`cat $TMP_DIR/fn_image.txt`
      auto_echo TF_VAR_fn_image=$TF_VAR_fn_image
      export TF_VAR_fn_db_url=`cat $TMP_DIR/fn_db_url.txt`
      auto_echo TF_VAR_fn_db_url=$TF_VAR_fn_db_url
    fi   
  fi

  # Container Instance
  if [ "$TF_VAR_deploy_strategy" == "container_instance" ]; then
    if [ -f $TMP_DIR/docker_image_ui.txt ]; then
      export TF_VAR_docker_image_ui=`cat $TMP_DIR/docker_image_ui.txt`
      if [ -f $TMP_DIR/docker_image_ui.txt ]; then
        export TF_VAR_docker_image_app=`cat $TMP_DIR/docker_image_app.txt`
      else
        export TF_VAR_docker_image_app="busybox"      
      fi
    fi
  fi

  # Compute
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

