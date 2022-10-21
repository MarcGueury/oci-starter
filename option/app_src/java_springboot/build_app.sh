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

# Check java version
if [ "$OCI_CLI_CLOUD_SHELL" == "true" ]; then
  ## XX Check Java Version in env variables
  export JAVA_ID=`csruntimectl java list | grep jdk-17 | sed -e 's/^.*\(graal[^ ]*\) .*$/\1/'`
  csruntimectl java set $JAVA_ID
fi

mvn package

if [ "$1" == "compute" ]; then
  # Replace the user and password
  cp start.sh target/.
  sed -i "s/##DB_USER##/$TF_VAR_db_user/" target/start.sh
  sed -i "s/##DB_PASSWORD##/$TF_VAR_db_password/" target/start.sh

  mkdir ../compute/app
  cp -r target/* ../compute/app/.

elif [ "$1" == "kubernetes" ]; then
  docker build -t app .
fi  
