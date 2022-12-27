#!/bin/bash
# Build_app.sh
#
# Build the common.sh file.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../../bin/build_common.sh

append () {
   echo "$1" >> ../../../common.sh
}

conditional_append() {
  if [[ "$COMMON" == *",$1,"* ]]; then
    append "# $1" 
    append "export $2=${!2}"
  fi
}

if [ -z "$TF_VAR_vcn_ocid" ]; then
   get_id_from_tfstate "TF_VAR_vcn_ocid" "starter_vcn"
fi   

if [ -z "$TF_VAR_subnet_ocid" ]; then
   get_id_from_tfstate "TF_VAR_subnet_ocid" "starter_subnet"
fi   

if [ -z "$TF_VAR_atp_ocid" ]; then
   get_id_from_tfstate "TF_VAR_atp_ocid" "starter_atp" 
fi   

if [ -z "$TF_VAR_db_ocid" ]; then
   get_id_from_tfstate "TF_VAR_db_ocid" "starter_dbsystem" 
fi   

if [ -z "$TF_VAR_mysql_ocid" ]; then
   get_id_from_tfstate "TF_VAR_mysql_ocid" "starter_mysql" 
fi   

get_output_from_tfstate "TF_VAR_oke_ocid" "oke_ocid"

if [ -z "$TF_VAR_apigw_ocid" ]; then
  get_id_from_tfstate "TF_VAR_apigw_ocid" "starter_apigw"
fi   

if [ -z "$TF_VAR_fnapp_ocid" ]; then
   get_id_from_tfstate "TF_VAR_fnapp_ocid" "starter_fn_application"
fi   

if [ -z "$TF_VAR_bastion_ocid" ]; then
  get_id_from_tfstate "TF_VAR_bastion_ocid" "starter_bastion"
fi

COMMON=,${TF_VAR_common},



cat > ../../../common.sh <<'EOT' 
COMMON_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
EOT

cat >> ../../../common.sh <<EOT 
# Commment to create an new oci-starter compartment automatically
# export TF_VAR_compartment_id=__TO_FILL__

# Common Resources Name (Typically: dev, test, qa, prod)
export TF_VAR_common_name=$TF_VAR_common_name

# Landing Zone
# export TF_VAR_lz_appdev_cmp_ocid=$TF_VAR_compartment_id
# export TF_VAR_lz_database_cmp_ocid=$TF_VAR_compartment_id
# export TF_VAR_lz_network_cmp_ocid=$TF_VAR_compartment_id
# export TF_VAR_lz_security_cmp_ocid=$TF_VAR_compartment_id

# Network
export TF_VAR_vcn_ocid=$TF_VAR_vcn_ocid
export TF_VAR_subnet_ocid=$TF_VAR_subnet_ocid

# Bastion
export TF_VAR_bastion_ocid=$TF_VAR_bastion_ocid

EOT

conditional_append autonomous TF_VAR_atp_ocid
conditional_append database TF_VAR_db_ocid
conditional_append mysql TF_VAR_mysql_ocid
conditional_append oke TF_VAR_oke_ocid
conditional_append apigw TF_VAR_apigw_ocid
conditional_append fnapp TF_VAR_fnapp_ocid

cat >> ../../../common.sh <<EOT 

# Database Password
export TF_VAR_db_password=$TF_VAR_db_password
# Auth Token
export TF_VAR_auth_token=$TF_VAR_auth_token

EOT

cat >> ../../../common.sh <<'EOT' 

# SSH Keys
export TF_VAR_ssh_public_key=$(cat $COMMON_DIR/target/ssh_key_starter.pub)
export TF_VAR_ssh_private_key=$(cat $COMMON_DIR/target/ssh_key_starter)
EOT