#!/bin/bash
# Build_app.sh
#
#!/bin/bash
# Parameter build or docker
# Compute:
# - build the code 
# - create a $ROOT/app directory with the compiled files
# - and a start.sh to start the program
# Docker:
# - build the image
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
if [ "$1" != "compute" ] && [ "$1" != "kubernetes" ] ; then
  echo 'Argument required: compute or kubernetes'
  exit
fi

# Replace the user and password in the configuration file (XXX)
CONFIG_FILE=src/main/resources/META-INF/microprofile-config.properties
sed -i "s/##DB_USER##/$TF_VAR_db_user/" $CONFIG_FILE
sed -i "s/##DB_PASSWORD##/$TF_VAR_db_password/" $CONFIG_FILE

# Check java version
if [ "$OCI_CLI_CLOUD_SHELL" == "true" ]; then
  ## XX Check Java Version in env variables
  export JAVA_ID=`csruntimectl java list | grep jdk-17 | sed -e 's/^.*\(graal[^ ]*\) .*$/\1/'`
  csruntimectl java set $JAVA_ID
fi

if [ "$1" == "compute" ]; then
  mvn package
  cp start.sh target/.
  mkdir ../compute/app
  cp -r target/* ../compute/app/.
elif [ "$1" == "kubernetes" ]; then
  docker image rm app:latest
  docker build -t app:latest .
fi  
