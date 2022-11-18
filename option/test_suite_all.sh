#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
export TEST_HOME=$SCRIPT_DIR/test_all
. $HOME/bin/env_oci_starter_testsuite.sh kubernetes

start_test () {
  export TEST_NAME=$1
  export TEST_DIR=$TEST_HOME/$OPTION_DEPLOY/$TEST_NAME
  echo "-- TEST: $OPTION_DEPLOY - $TEST_NAME ---------------------------------------"   
}

build_test_destroy () {
  SECONDS=0
  pwd
  cd $TEST_DIR
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
  # ./destroy.sh --auto-approve > destroy.log 2>&1  
  # echo "destroy_secs=" $SECONDS >> ${TEST_DIR}_time.txt
  cat ${TEST_DIR}_time.txt
}

build_option() {
  if [ "$OPTION_LANG" == "java" ]; then
    NAME=${OPTION_LANG}-${OPTION_JAVA_FRAMEWORK}-${OPTION_DB}-${OPTION_UI}
  else
    NAME=${OPTION_LANG}-${OPTION_DB}-${OPTION_UI}
  fi
  start_test $NAME
  cd $TEST_HOME/oci-starter
  ./oci_starter.sh -prefix $NAME -compartment_ocid $EX_COMPARTMENT_OCID -vcn_ocid $EX_VNC_OCID -subnet_ocid $EX_SUBNET_OCID -oke_ocid $EX_OKE_OCID -atp_ocid $EX_ATP_OCID -mysql_ocid $EX_MYSQL_OCID -bastion_ocid $EX_BASTION_OCID \
                  -language $OPTION_LANG -java_framework $OPTION_JAVA_FRAMEWORK -database $OPTION_DB -ui $OPTION_UI -deploy $OPTION_DEPLOY -db_password $TEST_DB_PASSWORD -auth_token $OCI_TOKEN  > ${TEST_DIR}.log 2>&1 
  mv output $TEST_DIR               
  build_test_destroy
}

loop_ui() {
  OPTION_UI=html 
  build_option
  # Test all the UIs with ORDS only
  if [ "$OPTION_LANG" == "ords" ]; then
    OPTION_UI=reactjs
    build_option
    OPTION_UI=angular
    build_option
    OPTION_UI=jet
    build_option
  fi 
}

loop_db() {
  OPTION_DB=atp 
  loop_ui
  OPTION_DB=mysql
  loop_ui
}

loop_java_framework () {
  OPTION_JAVA_FRAMEWORK=helidon 
  loop_db
  OPTION_JAVA_FRAMEWORK=springboot 
  loop_db
  OPTION_JAVA_FRAMEWORK=tomcat
  loop_db
}

loop_lang () {
  mkdir $TEST_HOME/$OPTION_DEPLOY
  if [ "$OPTION_DEPLOY" == "kubernetes" ]; then
    export EX_MYSQL_OCID=$EX_OKE_MYSQL_OCID
    export EX_VNC_OCID=$EX_OKE_VNC_OCID
    export EX_SUBNET_OCID=$EX_OKE_SUBNET_OCID
  else
    export EX_MYSQL_OCID=$EX_SHARED_MYSQL_OCID
    export EX_VNC_OCID=$EX_SHARED_VNC_OCID
    export EX_SUBNET_OCID=$EX_SHARED_SUBNET_OCID
  fi

  OPTION_LANG=java 
  if [ "$OPTION_DEPLOY" == "function" ]; then
    OPTION_JAVA_FRAMEWORK=fn
    loop_db
  else
    loop_java_framework
  fi
  OPTION_LANG=node 
  loop_db
  OPTION_LANG=python
  loop_db
  OPTION_LANG=dotnet
  loop_db
  # XXXX ORDS works only with ATP (DBSystems is not test/done)
  OPTION_LANG=ords
  OPTION_DB=atp 
  loop_ui
}

loop_deploy() {
  OPTION_DEPLOY=function 
  loop_lang
  OPTION_DEPLOY=oke
  loop_lang
  OPTION_DEPLOY=compute
  loop_lang
}

if [ -d $TEST_HOME ]; then
  echo "$TEST_HOME directory already exists"
  exit;
fi

# Avoid already set variables
unset "${!TF_VAR@}"

mkdir $TEST_HOME
cd $TEST_HOME
git clone https://github.com/mgueury/oci-starter

loop_deploy
