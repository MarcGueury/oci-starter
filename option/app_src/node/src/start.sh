
export ORACLE_SID=XE

export ORAENV_ASK=NO
source /opt/oracle/product/18c/dbhomeXE/bin/oraenv

#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

export DB_USER="##DB_USER##"
export DB_PASSWORD="##DB_PASSWORD##"
export DB_HOST="##DB_HOST##"
node rest.js