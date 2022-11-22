#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
export TEST_HOME=$SCRIPT_DIR/test
. $HOME/bin/env_oci_starter_testsuite.sh

#----------------------------------------------------------------------------
export EX_MYSQL_OCID=$EX_SHARED_MYSQL_OCID
export EX_VNC_OCID=$EX_SHARED_VNC_OCID
export EX_SUBNET_OCID=$EX_SHARED_SUBNET_OCID

#----------------------------------------------------------------------------
start_test () {
  export TEST_NAME=$1
  export TEST_DIR=$TEST_HOME/$TEST_NAME
  echo "-- Start test $TEST_NAME ---------------------------------------"   
  cd $TEST_HOME/oci-starter
}

build_test () {
  mv output $TEST_DIR
  SECONDS=0
  # Change to the TEST_HOME directory first in case that the creation of TEST_DIR failed
  cd $TEST_HOME
  cd $TEST_DIR
  pwd
  ./build.sh > build_$BUILD_ID.log 2>&1  
  echo "build_secs_$BUILD_ID=$SECONDS" >> ${TEST_DIR}_time.txt
  if [ -f /tmp/result.html ]; then
  if grep -q -i "DOCTYPE html" /tmp/result.html; then
      echo "RESULT HTML: OK"
    else
      echo "RESULT HTML: ***** BAD ******"
    fi
    if grep -q -i "deptno" /tmp/result.json; then
      echo "RESULT JSON: OK                "`cat /tmp/result.json | cut -c 1-80`... 
    else
      echo "RESULT JSON: ***** BAD ******  "`cat /tmp/result.json | cut -c 1-80`... 
    fi
    echo "RESULT INFO:                   "`cat /tmp/result.info | cut -c 1-80`
  else
    echo "No file /tmp/result.html"
  fi
  mv /tmp/result.html ${TEST_DIR}_result_$BUILD_ID.html
  mv /tmp/result.json ${TEST_DIR}_result_$BUILD_ID.json
  mv /tmp/result.info ${TEST_DIR}_result_$BUILD_ID.info
  mv /tmp/result_html.log ${TEST_DIR}_result_html_$BUILD_ID.log
  mv /tmp/result_json.log ${TEST_DIR}_result_json_$BUILD_ID.log
  mv /tmp/result_info.log ${TEST_DIR}_result_info_$BUILD_ID.log
}

build_test_destroy () {
  BUILD_ID=1
  build_test
  BUILD_ID=2
  build_test
  ./destroy.sh --auto-approve > destroy.log 2>&1  
  echo "destroy_secs=$SECONDS" >> ${TEST_DIR}_time.txt
  cat ${TEST_DIR}_time.txt
}

if [ -d test ]; then
  echo "test directory already exists"
  exit;
fi

# Avoid already set variables
unset "${!TF_VAR@}"

mkdir test
cd test
# git clone https://github.com/MarcGueury/oci-starter
git clone https://github.com/mgueury/oci-starter

date

OCI_STARTER="./oci_starter.sh -prefix test -compartment_ocid $EX_COMPARTMENT_OCID"

# Java Compute ATP / No Compartment
start_test 01_JAVA_HELIDON_COMPUTE_ATP
./oci_starter.sh -language java -deploy compute -db_password $TEST_DB_PASSWORD > $TEST_DIR.log 2>&1  
build_test_destroy

start_test 01B_JAVA_HELIDON_COMPUTE_ATP_RESOURCE_MANAGER
./oci_starter.sh -language java -deploy compute -db_password $TEST_DB_PASSWORD -iac resource_manager > $TEST_DIR.log 2>&1  
build_test_destroy

# Java Compute ATP + Existing Subnet
start_test 02_JAVA_HELIDON_COMPUTE_ATP_EX_SUBNET
$OCI_STARTER -language java -deploy compute -db_password $TEST_DB_PASSWORD -vcn_ocid $EX_VNC_OCID -subnet_ocid $EX_SUBNET_OCID > $TEST_DIR.log 2>&1  
build_test_destroy

# Wrong parameter
start_test 03_WRONG
$OCI_STARTER -toto hello > $TEST_DIR.log 2>&1  

# GraalVM
start_test 04_JAVA_HELIDON_COMPUTE_ATP_GRAALVM
$OCI_STARTER -language java -java_vm graalvm -deploy compute -db_password $TEST_DB_PASSWORD > $TEST_DIR.log 2>&1   
build_test_destroy

# SpringBoot
start_test 05_JAVA_SPRINGBOOT_COMPUTE_ATP
$OCI_STARTER -language java -java_framework springboot -deploy compute -db_password $TEST_DB_PASSWORD > $TEST_DIR.log 2>&1   
build_test_destroy

# SpringBoot Resource Manager
start_test 05B_JAVA_SPRINGBOOT_COMPUTE_ATP_RESOURCE_MANAGER
$OCI_STARTER -language java -java_framework springboot -deploy compute -db_password $TEST_DB_PASSWORD -iac resource_manager > $TEST_DIR.log 2>&1   
build_test_destroy

# DB System
start_test 06_JAVA_HELIDON_COMPUTE_DATABASE
$OCI_STARTER -language java -database database -deploy compute -db_password $TEST_DB_PASSWORD > $TEST_DIR.log 2>&1  
build_test_destroy

# Mysql + Helidon
start_test 07_JAVA_HELIDON_COMPUTE_MYSQL
$OCI_STARTER -language java -database mysql -deploy compute -db_password $TEST_DB_PASSWORD > $TEST_DIR.log 2>&1  
build_test_destroy

# Java Compute + Existing ATP + Existing Subnet
start_test 08_JAVA_HELIDON_COMPUTE_EX_ATP_SUBNET
$OCI_STARTER -language java -deploy compute -db_password $TEST_DB_PASSWORD -atp_ocid $EX_ATP_OCID -vcn_ocid $EX_VNC_OCID -subnet_ocid $EX_SUBNET_OCID > $TEST_DIR.log 2>&1  
build_test_destroy

# Java Compute + Existing DB + Existing Subnet
start_test 09_JAVA_HELIDON_COMPUTE_EX_DB_SUBNET
$OCI_STARTER -language java -deploy compute -database database -db_password $TEST_DB_PASSWORD -db_ocid $EX_DB_OCID -vcn_ocid $EX_VNC_OCID -subnet_ocid $EX_SUBNET_OCID > $TEST_DIR.log 2>&1  
build_test_destroy

# Java Compute + Existing MYSQL + Existing Subnet
start_test 10_JAVA_HELIDON_COMPUTE_EX_MYSQL_SUBNET
$OCI_STARTER -language java -deploy compute -database mysql -db_password $TEST_DB_PASSWORD -mysql_ocid $EX_MYSQL_OCID -vcn_ocid $EX_VNC_OCID -subnet_ocid $EX_SUBNET_OCID > $TEST_DIR.log 2>&1  
build_test_destroy

# Java Compute + Existing MYSQL + Existing Subnet
start_test 11_ORDS_COMPUTE_ATP
$OCI_STARTER -language ords -deploy compute -db_password $TEST_DB_PASSWORD > $TEST_DIR.log 2>&1  
build_test_destroy

# OKE + Helidon
start_test 50_JAVA_HELIDON_OKE_ATP
$OCI_STARTER -language java -deploy kubernetes -auth_token $OCI_TOKEN -db_password $TEST_DB_PASSWORD > $TEST_DIR.log 2>&1  
build_test_destroy

# OKE + Helidon + DB System
start_test 51_JAVA_SPRINGBOOT_OKE_MYSQL
$OCI_STARTER -language java -deploy kubernetes -database database -auth_token $OCI_TOKEN -db_password $TEST_DB_PASSWORD > $TEST_DIR.log 2>&1  
build_test_destroy

# OKE + SPRINGBOOT + MYSQL + RESOURCE MANAGER
start_test 52_JAVA_SPRINGBOOT_OKE_MYSQL_RESOURCEMANAGER
$OCI_STARTER -iac resource_manager -language java -java_framework springboot -deploy kubernetes -database mysql -auth_token $OCI_TOKEN -db_password $TEST_DB_PASSWORD > $TEST_DIR.log 2>&1  
build_test_destroy

# Function + JAVA + ATP
start_test 100_JAVA_FUNCTION
$OCI_STARTER -language java -deploy function -auth_token $OCI_TOKEN -db_password $TEST_DB_PASSWORD > $TEST_DIR.log 2>&1  
build_test_destroy

# Function + NODE + RESOURCEMANAGER
start_test 101_NODE_FUNCTION_RESOURCEMANAGER
$OCI_STARTER -iac resource_manager -language node -deploy function -auth_token $OCI_TOKEN -db_password $TEST_DB_PASSWORD > $TEST_DIR.log 2>&1  
build_test_destroy

date
