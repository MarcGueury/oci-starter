# Build_common.sh
# This file contains the common functions used by build_app.sh and build_ui.sh

### Commmon functions
# Check java version
check_java_version() {
    if [ "$OCI_CLI_CLOUD_SHELL" == "true" ]; then
    ## XX Check Java Version in env variables
    export JAVA_ID=`csruntimectl java list | grep jdk-17 | sed -e 's/^.*\(graal[^ ]*\) .*$/\1/'`
    csruntimectl java set $JAVA_ID
    fi
}

# SCRIPT_DIR should be set by the calling scripts 
cd $SCRIPT_DIR
if [ ! -v TF_VAR_deploy_strategy ]; then
  echo 'Variables not set. Before to run the script, please run:'
  echo '. bin/auto_env.sh'
  exit
fi  



