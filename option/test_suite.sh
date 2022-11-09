#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
# export EX_COMPARTMENT_OCID=
# export EX_VNC_OCID=
# export EX_SUBNET_OCID=
# export EX_OKE_OCID=
# export EX_ATP_OCID=
# export EX_DB_OCID=
# export EX_MYSQL_OCID=
# export OCI_TOKEN=
# export TEST_DB_PASSWORD=
. $HOME/bin/env_oci_starter_testsuite.sh compute

start_test () {
  export TEST_NAME=$1
  cd $SCRIPT_DIR/test
  echo "-- Start test $TEST_NAME ---------------------------------------"   
  cp -r oci-starter $TEST_NAME
  cd $TEST_NAME
}

build_test_destroy () {
  SECONDS=0
  TEST_DIR=$SCRIPT_DIR/test/$TEST_NAME
  pwd
  cd $TEST_DIR/output
  ./build.sh > build.log 2>&1  
  echo "build_secs=" $SECONDS >  ${TEST_DIR}_time.txt
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
  mv /tmp/result.html ${TEST_DIR}_result.html
  mv /tmp/result.json ${TEST_DIR}_result.json
  mv /tmp/result.info ${TEST_DIR}_result.info
  mv /tmp/result_html.log ${TEST_DIR}_result_html.log
  mv /tmp/result_json.log ${TEST_DIR}_result_json.log
  mv /tmp/result_info.log ${TEST_DIR}_result_info.log
  SECONDS=0
  ./destroy.sh --auto-approve > destroy.log 2>&1  
  echo "destroy_secs=" $SECONDS >> ${TEST_DIR}_time.txt
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
git clone https://github.com/MarcGueury/oci-starter

# Java Compute ATP 
start_test 01_JAVA_HELIDON_COMPUTE_ATP
./oci_starter.sh -language java -deploy compute -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

start_test 01B_JAVA_HELIDON_COMPUTE_ATP_RESOURCE_MANAGER
./oci_starter.sh -language java -deploy compute -db_password $TEST_DB_PASSWORD -iac resource_manager > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

# Java Compute ATP + Existing Subnet
start_test 02_JAVA_HELIDON_COMPUTE_ATP_EX_SUBNET
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -deploy compute -db_password $TEST_DB_PASSWORD -vcn_ocid $EX_VNC_OCID -subnet_ocid $EX_SUBNET_OCID > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

# Wrong parameter
start_test 03_WRONG
./oci_starter.sh -toto hello > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  

# GraalVM
start_test 04_JAVA_HELIDON_COMPUTE_ATP_GRAALVM
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -java_vm graalvm -deploy compute -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1   
build_test_destroy

# SpringBoot
start_test 05_JAVA_SPRINGBOOT_COMPUTE_ATP
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -java_framework springboot -deploy compute -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1   
build_test_destroy

start_test 05B_JAVA_SPRINGBOOT_COMPUTE_ATP_RESOURCE_MANAGER
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -java_framework springboot -deploy compute -db_password $TEST_DB_PASSWORD -iac resource_manager > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1   
build_test_destroy

# DB System
start_test 06_JAVA_HELIDON_COMPUTE_DATABASE
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -database database -deploy compute -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

# Mysql + SpringBoot
start_test 07_JAVA_SPRINGBOOT_COMPUTE_MYSQL
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -java_framework springboot -database mysql -deploy compute -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1   
build_test_destroy

# Mysql + Helidon
start_test 08_JAVA_HELIDON_COMPUTE_MYSQL
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -database mysql -deploy compute -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

# Node + Mysql
start_test 09_NODE_COMPUTE_MYSQL
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language node -database mysql -deploy compute -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

# Java Compute + Existing ATP + Existing Subnet
start_test 10_JAVA_HELIDON_COMPUTE_EX_ATP_SUBNET
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -deploy compute -db_password $TEST_DB_PASSWORD -atp_ocid $EX_ATP_OCID -vcn_ocid $EX_VNC_OCID -subnet_ocid $EX_SUBNET_OCID > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

# Java Compute + Existing DB + Existing Subnet
start_test 11_JAVA_HELIDON_COMPUTE_EX_DB_SUBNET
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -deploy compute -database database -db_password $TEST_DB_PASSWORD -db_ocid $EX_DB_OCID -vcn_ocid $EX_VNC_OCID -subnet_ocid $EX_SUBNET_OCID > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

# Java Compute + Existing MYSQL + Existing Subnet
start_test 12_JAVA_HELIDON_COMPUTE_EX_MYSQL_SUBNET
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -deploy compute -database mysql -db_password $TEST_DB_PASSWORD -mysql_ocid $EX_MYSQL_OCID -vcn_ocid $EX_VNC_OCID -subnet_ocid $EX_SUBNET_OCID > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

# OKE + Helidon
start_test 50_JAVA_HELIDON_OKE_ATP
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -deploy kubernetes -auth_token $OCI_TOKEN -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

# OKE + SPRINGBOOT
start_test 51_JAVA_SPRINGBOOT_OKE_ATP
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -java_framework springboot -deploy kubernetes -auth_token $OCI_TOKEN -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

# OKE + SPRINGBOOT + MYSQL
start_test 52_JAVA_SPRINGBOOT_OKE_MYSQL
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -java_framework springboot -deploy kubernetes -database mysql -auth_token $OCI_TOKEN -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy
