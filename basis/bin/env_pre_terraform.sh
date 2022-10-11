SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Variables
. $SCRIPT_DIR/../variables.sh

# Yum
sudo yum install jq -y

# Namespace
export TF_VAR_ssh_public_key=$(cat $SCRIPT_DIR/../id_devops_rsa.pub)
export TF_VAR_ssh_private_key=$(cat $SCRIPT_DIR/../id_devops_rsa)
export TF_VAR_compartment_name=`oci iam compartment get --compartment-id=$TF_VAR_compartment_ocid | jq -r .data.name`

# Echo
echo TF_VAR_tenancy_ocid=$TF_VAR_tenancy_ocid
echo TF_VAR_compartment_ocid=$TF_VAR_compartment_ocid
echo TF_VAR_compartment_name=$TF_VAR_compartment_name
echo TF_VAR_region=$TF_VAR_region

# Get config from file
if [ -f $HOME/.oci/config ]; then
  ## Get the [DEFAULT] config
  sed -n -e '/\[DEFAULT\]/,$p' $HOME/.oci/config > /tmp/ociconfig
  export TF_VAR_user_ocid=`sed -n 's/user=//p' /tmp/ociconfig |head -1`
  export TF_VAR_fingerprint=`sed -n 's/fingerprint=//p' /tmp/ociconfig |head -1`
  export TF_VAR_private_key_path=`sed -n 's/key_file=//p' /tmp/ociconfig |head -1`
  # echo TF_VAR_user_ocid=$TF_VAR_user_ocid
  # echo TF_VAR_fingerprint=$TF_VAR_fingerprint
  # echo TF_VAR_private_key_path=$TF_VAR_private_key_path
fi

