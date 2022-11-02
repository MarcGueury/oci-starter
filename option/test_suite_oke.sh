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
  # export EX_BASTION_OCID=
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

  build_test_destroy () {
    SECONDS=0
    TEST_DIR=$SCRIPT_DIR/test_oke/$TEST_NAME
    pwd
    cd $TEST_DIR/output
    ./build.sh > build.log 2>&1  
    echo "build_secs=" $SECONDS >  ${TEST_DIR}_time.txt
    if [ -f /tmp/result.html ]; then
      if grep -q "OCI Starter" /tmp/result.html; then
        echo RESULT HTML: OK 
      else
        echo RESULT HTML: ***** BAD ****** 
      fi
      if grep -q "deptno" /tmp/result.json; then
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
    if [ "$OPTION_LANG" == "java " ]; then
      NAME=${OPTION_LANG}-${OPTION_JAVA_FRAMEWORK}-${OPTION_DB}-${OPTION_UI}
    else
      NAME=${OPTION_LANG}-${OPTION_DB}-${OPTION_UI}
    fi
    start_test $NAME
    bash -x ./oci_starter.sh -compartment_ocid $EX_COMPARTMENT_OCID -vcn_ocid $EX_VNC_OCID -subnet_ocid $EX_SUBNET_OCID -oke_ocid $EX_OKE_OCID -atp_ocid $EX_ATP_OCID -bastion_ocid $EX_BASTION_OCID \
                    -language $OPTION_LANG -java_framework $OPTION_JAVA_FRAMEWORK -database $OPTION_DB -ui $OPTION_UI -deploy kubernetes -db_password $TEST_DB_PASSWORD -auth_token $OCI_TOKEN
    build_test_destroy
    exit
  }

  loop_ui() {
    OPTION_UI=html 
    build_option
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
    OPTION_LANG=java 
    loop_java_framework
    OPTION_LANG=node 
    loop_db
    OPTION_LANG=python
    loop_db
  }

  if [ -d test_oke ]; then
    echo "test_oke directory already exists"
    exit;
  fi

  # Avoid already set variables
  unset "${!TF_VAR@}"

  mkdir test_oke
  cd test_oke
  git clone https://github.com/MarcGueury/oci-starter

  loop_lang
