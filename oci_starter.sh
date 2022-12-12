#!/bin/bash
# OCI Starter
# 
# Script to create a directory or a zip file with the source code
# 
# Author: Marc Gueury
# Date: 2022-10-15
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

title() {
    TITLE="-- $1 ---------------------------------------------------------------------"
    echo ${TITLE:0:78} 
}

todo() {
    echo "-- TODO ---"
}

cp_terraform() {
    echo "cp_terraform $1"
    cp ../option/terraform/$1 src/terraform/.

    # Append a second file
    if [ ! -z "$2" ]; then
      echo "append $2"
      echo >> terraform/$1
      echo >> terraform/$1
      cat ../option/terraform/$2 >> src/terraform/$1
    fi
}

cp_dir_db_src() {
    echo "cp_dir_db_src $1"
    cp ../option/db_src/$1/* db_src/.
}

title oci_starter.sh 

# Avoid issue when developing
unset "${!TF_VAR@}"

# keeping this section here so that $MODE etc. are accessible after py_oci_starter.py has run
if [ "$#" -eq 3 ]; then
  export MODE=GIT
  export GIT_URL=$1
  export REPOSITORY_NAME=$2
  export OCI_USERNAME=$3
  echo GIT_URL=$GIT_URL
else
  export MODE=CLI
fi

rm -rf ./output 
if [ "$1" == "-zip" ]; then
   export MODE=ZIP
   export REPOSITORY_NAME="$2"
   mkdir $REPOSITORY_NAME
fi

echo "Generating env.sh using py_oci_starter.py:"

python3 py_oci_starter.py "$@"

# running this now so the rest of the script has access to the TF_VARs...
if [ ! -d output ]; then
  exit
fi
. ./output/env.sh

if [ "$MODE" == "ZIP" ]; then
  mv ./output/env.sh $REPOSITORY_NAME/.
fi

echo "py_oci_starter.py finished"

echo $TF_VAR_language

if [ $MODE == "GIT" ]; then
  git clone $GIT_URL
  cp ../mode/git/* $REPOSITORY_NAME/.
else 
  export REPOSITORY_NAME=${REPOSITORY_NAME:="output"}
  # mkdir $REPOSITORY_NAME (py_oci_starter.py creates the output directory anyway)
fi
cd ./$REPOSITORY_NAME

cp -r ../basis/* .
# mv ../env.sh . (py_oci_starter.py writes env.sh to the output directory anyway)

#-- README.md ------------------------------------------------------------------

cat > README.md <<EOF 
## OCI-Starter
### Usage 

### Commands
- build.sh      : Build the whole program: Run Terraform, Configure the DB, Build the App, Build the UI
- destroy.sh    : Destroy the objects created by Terraform
- env.sh        : Contains the settings of your project

### Directories
- app_src       : Source of the Application (Command: build_app.sh)
- ui_src        : Source of the User Interface (Command: build_ui.sh)
- db_src        : SQL files of the database
- terraform     : Terraforms scripts (Command: plan.sh / apply.sh)
EOF

case $TF_VAR_deploy_strategy in
"compute")
    echo "- compute       : Contains the Compute scripts" >> README.md
  ;;
"kubernetes")
    echo "- oke           : Contains the Kubernetes scripts (Command: deploy.sh)" >> README.md
  ;;
esac

echo >> README.md
echo "### Next Steps" >> README.md

if grep -q "__TO_FILL__" env.sh; then
  echo "- Edit the file env.sh. Some variables needs to be filled:" >> README.md
  echo >> README.md
  cat env.sh | grep __TO_FILL__ >> README.md
  echo >> README.md
fi
echo "- Run:" >> README.md
if [ "$MODE" == "CLI" ]; then
echo "  cd output" >> README.md
fi
echo "  ./build.sh" >> README.md

#-- Insfrastruture As Code --------------------------------------------------

# Default state local
cp -r ../option/infra_as_code/terraform_local/* src/terraform/.
if [ "$TF_VAR_infra_as_code" == "resource_manager" ]; then
  cp -r ../option/infra_as_code/resource_manager/* src/terraform/.
elif [ "$TF_VAR_infra_as_code" == "terraform_object_storage" ]; then
  cp -r ../option/infra_as_code/terraform_object_storage/* src/terraform/.
fi

#-- APP ---------------------------------------------------------------------

if [[ $TF_VAR_deploy_strategy == "function" ]]; then
  APP=fn/fn_$TF_VAR_language
else
  APP=$TF_VAR_language
  if [ "$TF_VAR_language" == "java" ]; then
    APP=${TF_VAR_language}_${TF_VAR_java_framework}
  fi
fi

case $TF_VAR_db_strategy in

"autonomous")
    APP_DB="oracle"
    ;;

"database")
    APP_DB="oracle"
    ;;

"mysql")
    APP_DB="mysql"
esac

APP_DB=${APP}_${APP_DB}
echo APP=$APP
mkdir app_src
mkdir db_src

# Function Common 
if [[ $TF_VAR_deploy_strategy == "function" ]]; then
  cp -r ../option/app_src/fn/fn_common/* src/app_src/.
fi  

# Generic version for Oracle DB
if [ -d "../option/app_src/$APP" ]; then
  cp -r ../option/app_src/$APP/* src/app_src/.
fi

# Overwrite the generic version (ex for mysql)
if [ -d "../option/app_src/$APP_DB" ]; then
  cp -r ../option/app_src/$APP_DB/* src/app_src/.
fi

if [ "$TF_VAR_language" == "java" ]; then
   # FROM ghcr.io/graalvm/jdk:java17
   # FROM openjdk:17 
   # FROM openjdk:17-jdk-slim
   if [ "$TF_VAR_java_vm" == "graalvm" ]; then
     sed -i "s&##DOCKER_IMAGE##&ghcr.io/graalvm/jdk:java17&" src/app_src/Dockerfile 
   else
     sed -i "s&##DOCKER_IMAGE##&openjdk:17-jdk-slim&" src/app_src/Dockerfile 
   fi  
fi

#-- User Interface ----------------------------------------------------------

if [[ $TF_VAR_ui_strategy == "None" ]]; then
  echo "No UI"
else
  UI=`echo "$TF_VAR_ui_strategy" | awk '{print tolower($0)}'`
  cp -r ../option/ui_src/$UI/* src/ui_src/.
fi

#-- Network -----------------------------------------------------------------

if [[ $TF_VAR_vcn_strategy == "new" ]]; then
  cp_terraform network.tf 
else
  cp_terraform network_existing.tf 
fi

#-- Deployment --------------------------------------------------------------
if [[ $TF_VAR_deploy_strategy == "kubernetes" ]]; then
  if [[ $TF_VAR_kubernetes_strategy == "OKE" ]]; then
    if [[ $TF_VAR_oke_strategy == "new" ]]; then
      cp_terraform oke.tf oke_append.tf 
    else
      cp_terraform oke_existing.tf oke_append.tf 
    fi   
  fi
  mkdir src/oke 
  cp -r ../option/oke/* src/oke/.
  mv src/oke/*.sh bin/.

  if [ -f src/app_src/ingress-app.yaml ]; then
    mv src/app_src/ingress-app.yaml src/oke/.
  fi

  sed -i "s&##PREFIX##&${TF_VAR_prefix}&" src/app_src/app.yaml 
  sed -i "s&##PREFIX##&${TF_VAR_prefix}&" src/ui_src/ui.yaml
  sed -i "s&##PREFIX##&${TF_VAR_prefix}&" src/oke/ingress-app.yaml 
  sed -i "s&##PREFIX##&${TF_VAR_prefix}&" src/oke/ingress-ui.yaml
elif [[ $TF_VAR_deploy_strategy == "function" ]]; then
  if [ -v TF_VAR_fnapp_ocid ]; then
    cp_terraform function_existing.tf function_append.tf
  else
    cp_terraform function.tf function_append.tf
  fi
  if [ "$TF_VAR_language" == "ords" ]; then
    APIGW_APPEND=apigw_fn_ords_append.tf
  else 
    APIGW_APPEND=apigw_fn_append.tf
  fi

  if [ -v TF_VAR_apigw_ocid ]; then
    cp_terraform apigw_existing.tf $APIGW_APPEND
  else
    cp_terraform apigw.tf $APIGW_APPEND
  fi
elif [[ $TF_VAR_deploy_strategy == "compute" ]]; then
  cp_terraform compute.tf
  mkdir src/compute 
  cp ../option/compute/* src/compute/.
elif [[ $TF_VAR_deploy_strategy == "container_instance" ]]; then 
  cp_terraform container_instance.tf 
  mkdir src/container_instance 
  cp ../option/container_instance/* bin/.

  if [ "$TF_VAR_language" == "ords" ]; then
    APP_URL="\${local.ords_url}/starter/module/\$\${request.path[pathname]}"
  elif [ "$TF_VAR_language" == "java" ] && [ "$TF_VAR_java_framework" == "tomcat" ]; then
    APP_URL="http://\${local.ci_private_ip}:8080/starter-1.0/\$\${request.path[pathname]}"
  else 
    APP_URL="http://\${local.ci_private_ip}:8080/\$\${request.path[pathname]}"
  fi

  if [ -v TF_VAR_apigw_ocid ]; then
    cp_terraform apigw_existing.tf apigw_ci_append.tf
    sed -i "s&##APP_URL##&${APP_URL}&" src/terraform/apigw_existing.tf
  else
    cp_terraform apigw.tf apigw_ci_append.tf
    sed -i "s&##APP_URL##&${APP_URL}&" src/terraform/apigw.tf
  fi
fi

#-- Bastion -----------------------------------------------------------------
if [ -n "$TF_VAR_bastion_ocid" ]; then
  cp_terraform bastion_existing.tf  
else
  cp_terraform bastion.tf  
fi 

#-- Database ----------------------------------------------------------------
cp_terraform output.tf 

if [[ $TF_VAR_db_strategy == "autonomous" ]]; then
  cp_dir_db_src oracle
  if [[ $TF_VAR_db_existing_strategy == "new" ]]; then
    cp_terraform atp.tf atp_append.tf
  else
    cp_terraform atp_existing.tf atp_append.tf
  fi   
elif [[ $TF_VAR_db_strategy == "database" ]]; then
  cp_dir_db_src oracle
  if [[ $TF_VAR_db_existing_strategy == "new" ]]; then
    cp_terraform dbsystem.tf dbsystem_append.tf
  else
    cp_terraform dbsystem_existing.tf dbsystem_append.tf
  fi   
elif [[ $TF_VAR_db_strategy == "mysql" ]]; then  
  cp_dir_db_src mysql
  if [[ $TF_VAR_db_existing_strategy == "new" ]]; then
    cp_terraform mysql.tf mysql_append.tf
  else
    cp_terraform mysql_existing.tf mysql_append.tf
  fi   
fi

# ORDS Case
if [ -f app_src/oracle.sql ]; then
  mv app_src/oracle.sql src/db_src/.
fi

title "Done"
echo Directory $REPOSITORY_NAME created.

if [ "$MODE" == "GIT" ]; then
  #-- Commit in devops git ----------------------------------------------------
  git config --local user.email "test@example.com"
  git config --local user.name "${OCI_USERNAME}"
  git add .
  git commit -m "added latest files"
  git push origin main
elif [ "$MODE" == "ZIP" ]; then
  # The goal is to have a file that when uncompressed create a directory prefix.
  cd ..
  mkdir -p zip/$REPOSITORY_NAME
  mv $REPOSITORY_NAME zip/$REPOSITORY_NAME/$TF_VAR_prefix
  cd zip/$REPOSITORY_NAME
  zip -r ../$REPOSITORY_NAME.zip $TF_VAR_prefix
else
  echo
  cat README.md
fi

  