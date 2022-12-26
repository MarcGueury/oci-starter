#!/bin/bash
# Build_app.sh
#
# Build the common.sh file.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. $SCRIPT_DIR/../../bin/build_common.sh

cat > ../../../common.sh <<EOT 

# Commment to create an new oci-starter compartment automatically
# export TF_VAR_compartment_id=__TO_FILL__

# Environment Name (Typically: dev, test, qa, prod)
export TF_VAR_env=$TF_VAR_PREFIX

# Landing Zone
export TF_VAR_lz_appdev_cmp_ocid=$TF_VAR_compartment_id
export TF_VAR_lz_database_cmp_ocid=$TF_VAR_compartment_id
export TF_VAR_lz_network_cmp_ocid=$TF_VAR_compartment_id
export TF_VAR_lz_security_cmp_ocid=$TF_VAR_compartment_id

# Network
export TF_VAR_vcn_ocid=$TF_VAR_vcn_ocid
export TF_VAR_subnet_ocid=$TF_VAR_subnet_ocid

# ATP
export TF_VAR_atp_ocid=$TF_VAR_atp_ocid
# DB System
export TF_VAR_db_ocid=$TF_VAR_db_ocid
# MySQL
export TF_VAR_mysql_ocid=$TF_VAR_mysql_ocid

# Database Password
export TF_VAR_db_password=$TF_VAR_db_password

# OKE
export TF_VAR_oke_ocid=$TF_VAR_oke_ocid
# APIGW
export TF_VAR_apigw_ocid=$TF_VAR_apigw_ocid
# FNAPP
export TF_VAR_fnapp_ocid=$TF_VAR_fnapp_ocid

EOT