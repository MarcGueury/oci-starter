#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
. $HOME/bin/env_oci_starter_testsuite.sh
export BUILD_COUNT=1

# No color for terraforms logs
export nocolorarg=1

start_test() {
  export TEST_NAME=$1
  export TEST_DIR=$TEST_HOME/$OPTION_DEPLOY/$TEST_NAME
  echo "-- TEST: $OPTION_DEPLOY - $TEST_NAME ---------------------------------------"   
}

# Speed test of 100 calls
test_run_100() {
  SECONDS=0
  UI_URL=`cat /tmp/ui_url.txt`
  x=0 
  CSV_RUN100_OK=0
  while [ $x -le 100 ]
    do
      curl $UI_URL/app/dept -s -D /tmp/speed_json.log > /tmp/speed.json
      if grep -q -i "deptno" /tmp/speed.json; then
         CSV_RUN100_OK=$(( $CSV_RUN100_OK + 1 ))
      fi
      x=$(( $x + 1 ))
    done  
  CSV_RUN100_SECOND=$SECONDS
  echo "CSV_RUN100_SECOND=$CSV_RUN100_SECOND"
  echo "CSV_RUN100_OK=$OK_COUNT"
}

build_test () {
  SECONDS=0
  # Change to the TEST_HOME directory first in case that the creation of TEST_DIR failed
  cd $TEST_HOME
  cd $TEST_DIR
  pwd
  ./build.sh > build_$BUILD_ID.log 2>&1

  CSV_NAME=$NAME
  CSV_DIR=$TEST_DIR
  CSV_DATE=`date '+%Y%m%d-%H%M%S'`
  CSV_BUILD_SECOND=$SECONDS
  CSV_HTML_OK=0
  CSV_JSON_OK=0
  CSV_RUN100_SECOND=0

  echo "build_secs_$BUILD_ID=$SECONDS" >> ${TEST_DIR}_time.txt
  if [ -f /tmp/result.html ]; then
    if grep -q -i "starter" /tmp/result.html; then
      echo "RESULT HTML: OK"
      CSV_HTML_OK=1
    else
      echo "RESULT HTML: ***** BAD ******"
    fi
    if grep -q -i "deptno" /tmp/result.json; then
      echo "RESULT JSON: OK                "`cat /tmp/result.json | cut -c 1-80`... 
      CSV_JSON_OK=1
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

  if [ "$CSV_JSON_OK" == "1" ]; then
    test_run_100
  fi   
}

build_test_destroy () {
  BUILD_ID=1
  build_test
  if [ "$BUILD_COUNT" = "2" ]; then
    BUILD_ID=2
    build_test
  fi  
  ./destroy.sh --auto-approve > destroy.log 2>&1  
  echo "destroy_secs=$SECONDS" >> ${TEST_DIR}_time.txt
  CSV_DESTROY_SECOND=$SECONDS
  cat ${TEST_DIR}_time.txt

  echo "$CSV_DATE, $OPTION_DEPLOY, $CSV_NAME, $CSV_HTML_OK, $CSV_JSON_OK, $CSV_BUILD_SECOND, $CSV_DESTROY_SECOND, $CSV_RUN100_OK, $CSV_RUN100_SECOND" >> $TEST_HOME/result.csv 
}

build_option() {
  if [ "$OPTION_LANG" == "java" ] && [ "$OPTION_DEPLOY" != "function" ]; then
    NAME=${OPTION_LANG}-${OPTION_JAVA_FRAMEWORK}-${OPTION_JAVA_VM}-${OPTION_DB}-${OPTION_UI}
  else
    NAME=${OPTION_LANG}-${OPTION_DB}-${OPTION_UI}
  fi
  start_test $NAME
  cd $TEST_HOME/oci-starter
  ./oci_starter.sh \
       -prefix $NAME \
       -deploy $OPTION_DEPLOY \
       -ui $OPTION_UI \
       -language $OPTION_LANG \
       -java_framework $OPTION_JAVA_FRAMEWORK \
       -java_vm $OPTION_JAVA_VM \
       -database $OPTION_DB \
       -db_password $TEST_DB_PASSWORD \
       -compartment_ocid $EX_COMPARTMENT_OCID \
       -vcn_ocid $TF_VAR_vcn_ocid \
       -public_subnet_ocid $TF_VAR_public_subnet_ocid \
       -private_subnet_ocid $TF_VAR_private_subnet_ocid \
       -oke_ocid $TF_VAR_oke_ocid \
       -atp_ocid $TF_VAR_atp_ocid \
       -mysql_ocid $TF_VAR_mysql_ocid \
       -auth_token $OCI_TOKEN \
       -apigw_ocid $TF_VAR_apigw_ocid \
       -bastion_ocid $TF_VAR_bastion_ocid \
       -fnapp_ocid $TF_VAR_fnapp_ocid > ${TEST_DIR}.log 2>&1 

#       -db_ocid $TF_VAR_db_ocid \
#       -db_compartment_ocid $EX_COMPARTMENT_OCID \


  if [ -d output ]; then 
    mkdir output/target
    cp $TEST_HOME/group_common/target/ssh* output/target/.
    mv output $TEST_DIR               
    build_test_destroy
  else
    echo "Error: no output directory"  
  fi  
}

pre_test_suite() {
  if [ -d $TEST_HOME ]; then
    echo "$TEST_HOME directory already exists"
    exit;
  fi

  # Avoid already set variables
  unset "${!TF_VAR@}"

  mkdir $TEST_HOME
  cd $TEST_HOME
  git clone https://github.com/mgueury/oci-starter

  cd $TEST_HOME/oci-starter
  ./oci_starter.sh -group_name tsall -group_common atp,mysql,fnapp,apigw,oke -compartment_ocid $EX_COMPARTMENT_OCID -db_password $TEST_DB_PASSWORD -auth_token $OCI_TOKEN
  mv output/group_common ../group_common
  cd $TEST_HOME/group_common
  ./build.sh
  date
  echo "CSV_DATE, OPTION_DEPLOY, CSV_NAME, CSV_HTML_OK, CSV_JSON_OK, CSV_BUILD_SECOND, CSV_DESTROY_SECOND, CSV_RUN100_OK, CSV_RUN100_SECOND" > $TEST_HOME/result.csv 
}

post_test_suite() {
  date

  cd $TEST_HOME/group_common
  ./destroy.sh --auto-approve
}

