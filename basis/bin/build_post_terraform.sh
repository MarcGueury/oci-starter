#!/bin/bash
# Autonomous 

# Get the wallet
oci db autonomous-database generate-wallet --autonomous-database-id ${TF_VAR_atp_ocid} --file wallet.zip --password welcome1

export DB_URL=jdbc:oracle:thin:@adbhost?TNS_ADMIN=/Users/example/oracle/wallets/adb1
export DB_USER=$TF_VAR_db_user
export DB_PASSWORD=$TF_VAR_db_password
