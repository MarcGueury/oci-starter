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
. $HOME/bin/env_oci_starter_testsuite.sh

start_test () {
  export TEST_NAME=$1
  cd $SCRIPT_DIR/test
  echo "-- Start test $TEST_NAME ---------------------------------------"   
  cp -r oci-starter $TEST_NAME
  cd $TEST_NAME
}

get_output_from_tfstate () {
  RESULT=`jq -r '.outputs."'$2'".value' terraform/terraform.tfstate`
  echo "$1=$RESULT"
  export $1=$RESULT
}

build_test_destroy () {
  echo "-- Build test $TEST_NAME ---------------------------------------"   
  cd $SCRIPT_DIR/test/$TEST_NAME/output
  ./build.sh > build.log 2>&1  
  cp /tmp/result.html $SCRIPT_DIR/test/${TEST_NAME}_result.html
  cp /tmp/result.json $SCRIPT_DIR/test/${TEST_NAME}_result.json
  ./destroy.sh --auto-approve > destroy.log 2>&1  
}

if [ -d test ]; then
  echo "test directory already exists"
  exit;
di

mkdir test
cd test
git clone https://github.com/MarcGueury/oci-starter

# Java Compute ATP 
start_test JAVA_HELIDON_COMPUTE_ATP
./oci_starter.sh -language java -deploy compute -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

# Java Compute ATP + Existing Subnet
start_test JAVA_HELIDON_COMPUTE_ATP_EX_SUBNET
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -deploy compute -db_password $TEST_DB_PASSWORD -vcn_ocid $EX_VNC_OCID -subnet_ocid $EX_SUBNET_OCID > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

# Wrong parameter
start_test WRONG
./oci_starter.sh -toto hello > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  

# GraalVM
start_test JAVA_HELIDON_COMPUTE_ATP_GRAALVM
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -java_vm graalvm -deploy compute -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1   
build_test_destroy

# SpringBoot
start_test JAVA_SPRINGBOOT_COMPUTE_ATP
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -java_framework springboot -deploy compute -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1   
build_test_destroy

# DB System
start_test JAVA_HELIDON_COMPUTE_DATABASE
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -database database -deploy compute -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

# Mysql + SpringBoot
start_test JAVA_SPRINGBOOT_COMPUTE_MYSQL
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -java_framework springboot -database mysql -deploy compute -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1   
build_test_destroy

# Mysql + Helidon
start_test JAVA_HELIDON_COMPUTE_MYSQL
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -database mysql -deploy compute -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy

# OKE + Helidon
start_test JAVA_HELIDON_OKE_ATP
./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -language java -deploy kubernetes -token $OCI_TOKEN -db_password $TEST_DB_PASSWORD > $SCRIPT_DIR/test/${TEST_NAME}.log 2>&1  
build_test_destroy
