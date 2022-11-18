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
    cp ../option/terraform/$1 terraform/.

    # Append a second file
    if [ ! -z "$2" ]; then
      echo "append $2"
      echo >> terraform/$1
      echo >> terraform/$1
      cat ../option/terraform/$2 >> terraform/$1
    fi
}

cp_dir_db_src() {
    echo "cp_dir_db_src $1"
    cp ../option/db_src/$1/* db_src/.
}

mandatory() {
  if [ -z "$2" ]; then
    echo "Usage: oci-starter.sh [OPTIONS]"
    echo "Error: missing option -$1"
    exit
  fi
}

unknown_value() {
  echo "Usage: oci-starter.sh [OPTIONS]"
  echo "Unknown value for parameter:  $1" 
  echo "Allowed values: $2"
  exit
}

default() {
  if [ ! -v $1 ]; then
    export $1="$2"
  fi
}

show_help() {
  cat <<EOF
Usage: $(basename $0) [OPTIONS]

oci-starter.sh
   -prefix (default starter)
   -compartment_ocid (default tenancy_ocid)
   -language (mandatory) java / node / python / dotnet / ords 
   -deploy (mandatory) compute/kubernetes/function
   -java_framework (default helidon/springboot/tomcat)
   -java_vm (default jdk/graalvm)  
   -java_version (default 17/11/8)
   -kubernetes (default oke/docker) 
   -oke_ocid ()
   -ui (default html/reactjs/jet/angular/none) 
   -vcn_ocid()
   -subnet_ocid()
   -database (default atp/dbsystem/mysql)
   -atp_ocid (optional)
   -db_ocid (optional)
   -mysql_ocid (optional)
   -db_user (default admin)
   -db_password( mandatory )
EOF
}

title oci_starter.sh 

# Avoid issue when developing
unset "${!TF_VAR@}"

if [ "$#" -eq 3 ]; then
  export MODE=GIT
  export GIT_URL=$1
  export REPOSITORY_NAME=$2
  export OCI_USERNAME=$3
  echo GIT_URL=$GIT_URL
else
  export MODE=CLI
  if [ "$#" -eq 0 ]; then
    show_help
  fi

# Default
# export TF_VAR_tenancy_ocid="${var.tenancy_ocid}"
# export TF_VAR_region="${var.region}"
# export TF_VAR_compartment_ocid="${var.compartment_id}"
export TF_VAR_prefix="starter"
# export TF_VAR_language="${var.language}"
# export TF_VAR_java_framework=helidon
# export TF_VAR_java_vm=jdk
# export TF_VAR_java_version=17
export TF_VAR_vcn_strategy="new"
# export TF_VAR_vcn_ocid="${var.vcn_ocid}"
# export TF_VAR_subnet_ocid="${var.subnet_ocid}"
export TF_VAR_ui_strategy="html"
# export TF_VAR_deploy_strategy="${var.deploy_strategy}"
#export TF_VAR_kubernetes_strategy="oke"
# export TF_VAR_oke_strategy="new"
# export TF_VAR_oke_ocid="${var.oke_ocid}"
export TF_VAR_db_strategy="autonomous"
export TF_VAR_db_existing_strategy="new"
# export TF_VAR_atp_ocid="${var.atp_ocid}"
# export TF_VAR_db_ocid="${var.db_ocid}"
# export TF_VAR_mysql_ocid="${var.mysql_ocid}"
# export TF_VAR_apigw_ocid="${var.apigw_ocid}"
export TF_VAR_db_user="admin"
# XXXXXX export TF_VAR_vault_secret_authtoken_ocid=XXXXXXX
# export TF_VAR_db_password="${var.db_password}"
default TF_VAR_licence_model LICENSE_INCLUDED

while [[ $# -gt 0 ]]; do
  case $1 in
    -p|-prefix)
      export TF_VAR_prefix="$2"
      shift # past argument
      shift # past value
      ;;
    -compartment_ocid)
      export TF_VAR_compartment_ocid="$2"
      shift # past argument
      shift # past value
      ;;
    -language)
      if [ $2 == "java" ]; then 
        export TF_VAR_language=$2
        default TF_VAR_java_version 17
        default TF_VAR_java_framework helidon
      elif [ $2 == "node" ]; then  
        export TF_VAR_language=$2
      elif [ $2 == "python" ]; then  
        export TF_VAR_language=$2
      elif [ $2 == "dotnet" ]; then  
        export TF_VAR_language=$2
      elif [ $2 == "ords" ]; then  
        export TF_VAR_language=$2
      else
        unknown_value "$1" "java/node/python/ords"
      fi
      shift # past argument
      shift # past value
      ;;
    -deploy)
      if [ $2 == "compute" ]; then 
        export TF_VAR_deploy_strategy=$2
      elif [ $2 == "kubernetes" ] || [ $2 == "oke" ]  ; then  
        export TF_VAR_deploy_strategy="kubernetes"
        default TF_VAR_kubernetes_strategy OKE
        default TF_VAR_oke_strategy "new"
      elif [ $2 == "function" ]; then  
        export TF_VAR_deploy_strategy=$2
      else
        unknown_value "$1" "compute/kubernetes/function"
      fi
      shift # past argument
      shift # past value
      ;;      
    -java_framework)
      if [ $2 == "springboot" ]; then 
        export TF_VAR_java_framework=$2
      elif [ $2 == "helidon" ]; then  
        export TF_VAR_java_framework=$2
      elif [ $2 == "tomcat" ]; then  
        export TF_VAR_java_framework=$2        
      else
        unknown_value "$1" "springboot/helidon/tomcat"
      fi
      shift # past argument
      shift # past value
      ;;   
    -java_vm)
      if [ $2 == "jdk" ]; then 
        export TF_VAR_java_vm="jdk"
      elif [ $2 == "graalvm" ]; then  
        export TF_VAR_java_vm="graalvm"
      else
        unknown_value "$1" "jdk/graalvm"
      fi
      shift # past argument
      shift # past value
      ;;
    -java_version)
      export TF_VAR_java_version=$1
      if [ $1 != "8" ] && [ $1 != "11" ] &&[ $1 != "17" ]; then  
        unknown_value "$1" "8/11/17"
      fi
      shift # past argument
      shift # past value
      ;;      
    -kubernetes)
      if [ $2 == "oke" ]; then 
        export TF_VAR_kubernetes_strategy="OKE"
      elif [ $2 == "docker" ]; then  
        export TF_VAR_kubernetes_strategy="Docker image only"
      else
        unknown_value "$1" "oke/docker"
      fi
      shift # past argument
      shift # past value
      ;;          
    -oke_ocid)
      export TF_VAR_oke_strategy="existing"
      export TF_VAR_oke_ocid="$2"
      shift # past argument
      shift # past value
      ;;
    -ui)
      if [ $2 == "html" ]; then 
        export TF_VAR_ui_strategy="html"
      elif [ $2 == "jet" ]; then  
        export TF_VAR_ui_strategy="jet"        
      elif [ $2 == "angular" ]; then  
        export TF_VAR_ui_strategy="angular"        
      elif [ $2 == "reactjs" ]; then  
        export TF_VAR_ui_strategy="ReactJS"
      elif [ $2 == "none" ]; then  
        export TF_VAR_ui_strategy="None"        
      else
        unknown_value "$1" "html/reactjs/none"
      fi
      shift # past argument
      shift # past value
      ;;   
    -vcn_ocid)
      export TF_VAR_vcn_strategy="existing"
      export TF_VAR_vcn_ocid="$2"
      shift # past argument
      shift # past value
      ;;
    -subnet_ocid)
      export TF_VAR_subnet_ocid="$2"
      shift # past argument
      shift # past value
      ;;     
    -d|-database)
      if [ $2 == "atp" ] || [ $2 == "autonomous" ]; then 
        export TF_VAR_db_strategy="autonomous"
      elif [ $2 == "dbsystem" ] || [ $2 == "database" ]; then  
        export TF_VAR_db_strategy="database"
      elif [ $2 == "mysql" ]; then  
        export TF_VAR_db_strategy="mysql"        
      else
        unknown_value "$1" "atp/dbsystem/mysql"
      fi
      shift # past argument
      shift # past value
      ;;  
    -atp_ocid)
      export TF_VAR_db_existing_strategy="existing"
      export TF_VAR_atp_ocid="$2"
      shift # past argument
      shift # past value
      ;;    
    -db_ocid)
      export TF_VAR_db_existing_strategy="existing"
      export TF_VAR_db_ocid="$2"
      shift # past argument
      shift # past value
      ;;    
    -mysql_ocid)
      export TF_VAR_db_existing_strategy="existing"
      export TF_VAR_mysql_ocid="$2"
      shift # past argument
      shift # past value
      ;;     
    -bastion_ocid)
      export TF_VAR_bastion_ocid="$2"
      shift # past argument
      shift # past value
      ;;           
    -apigw_ocid)
      export TF_VAR_apigw_ocid="$2"
      shift # past argument
      shift # past value
      ;;                                   
    -db_user)
      export TF_VAR_db_user="$2"
      shift # past argument
      shift # past value
      ;;                            
    -db_password)
      export TF_VAR_db_password="$2"
      shift # past argument
      shift # past value
      ;;   
    -auth_token)
      export TF_VAR_auth_token="$2"
      shift # past argument
      shift # past value
      ;;        
    -zip)
      export MODE=ZIP
      export REPOSITORY_NAME="$2"
      shift # past argument
      shift # past value
      ;;      
    -iac|-infra_as_code)
      if [ $2 == "terraform_local" ]; then 
        export TF_VAR_infra_as_code=$2
      elif [ $2 == "terraform_object_storage" ]; then  
        export TF_VAR_infra_as_code=$2
      elif [ $2 == "resource_manager" ]; then  
        export TF_VAR_infra_as_code=$2        
      else
        unknown_value "$1" "terraform_local/terraform_object_storage/resource_manager"
      fi
      shift # past argument
      shift # past value
      ;;    
    -license)
      # BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED
      if [ $2 == "BRING_YOUR_OWN_LICENSE" ] || [ $2 == "byol" ] ; then 
        export TF_VAR_licence_model="BRING_YOUR_OWN_LICENSE"
      elif [ $2 == "LICENSE_INCLUDED" ] || [ $2 == "included" ]  ; then  
        export TF_VAR_licence_model="LICENSE_INCLUDED"
      else
        unknown_value "$1" "byol/BRING_YOUR_OWN_LICENSE/included/LICENSE_INCLUDED"
      fi
      shift # past argument
      shift # past value
      ;;            

    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

# XXXX The check should be placed somewhere else such that they are applied in all modes !!!
mandatory "language" $TF_VAR_language
mandatory "deploy" $TF_VAR_deploy_strategy
mandatory "db_password" $TF_VAR_db_password

if [ "$TF_VAR_db_existing_strategy" == "existing" ]; then
  if [ "$TF_VAR_db_strategy" == "autonomous" ]; then
     mandatory "atp_ocid" $TF_VAR_atp_ocid
  fi

  if [ "$TF_VAR_db_strategy" == "database" ]; then
     mandatory "db_ocid" $TF_VAR_db_ocid
  fi

  if [ "$TF_VAR_db_strategy" == "mysql" ]; then
     mandatory "mysql_ocid" $TF_VAR_mysql_ocid
  fi
fi    

if [ "$TF_VAR_language" != "java" ]; then  
  unset TF_VAR_java_framework
fi

if [ "$TF_VAR_deploy_strategy" != "compute" ] && [ -z "$TF_VAR_auth_token" ]; then
  echo "WARNING: token is not defined."
  echo "         You will need to define it in the file env.sh"
  export TF_VAR_auth_token="__TO_FILL__"
fi

if [ -z "$TF_VAR_compartment_ocid" ]; then
  echo "WARNING: compartment_ocid is not defined."
  echo "         The components will be created in the root compartment."
fi

# To avoid issue, Helidon support only jdk 17
if [ "$TF_VAR_java_framework" == "helidon" ] && [ "$TF_VAR_java_version" != "17" ]; then  
  echo "WARNING: Helidon supports only Java 17."
  echo "         Forcing the version to 17"
  export TF_VAR_java_version=17
fi

# Default user of database
if [ "$TF_VAR_db_strategy" == "database" ] && [ "$TF_VAR_db_user" == "admin" ]; then  
  echo "WARNING: Default user in Oracle Database System is system"
  echo "         Forcing the db_user to system"
  export TF_VAR_db_user="system"
fi

# Default user of MySQL
if [ "$TF_VAR_db_strategy" == "mysql" ] && [ "$TF_VAR_db_user" == "admin" ]; then  
  echo "WARNING: Default user in MySQL is root"
  echo "         Forcing the db_user to root"
  export TF_VAR_db_user="root"
fi

# Create env.sh
echo '#!/bin/bash' > env.sh
echo 'SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )' >> env.sh
echo '' >> env.sh
echo '# Env Variables' >> env.sh
if [ -z TF_VAR_compartment_ocid ]; then
  echo "# export TF_VAR_compartment_ocid=xxxxx"
fi
OCI_STARTER_CREATION_DATE=`date '+%Y-%m-%d-%H-%M-%S'`
echo "declare -x OCI_STARTER_CREATION_DATE=$OCI_STARTER_CREATION_DATE"
export |grep TF_VAR >> env.sh
echo '' >> env.sh
echo '# Get other env variables automatically' >> env.sh
echo '. $SCRIPT_DIR/bin/auto_env.sh' >> env.sh

# Add comment
sudo sed -i '/TF_VAR_licence_model/ i # TF_VAR_licence_model=BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED' env.sh

fi  

echo MODE=$MODE

title "Creating Directory"  
# java -version
# node --version
# python -version
# docker -version
# fn version

# uname -a
# curl -L -O https://helidon.io/cli/latest/darwin/helidon
# chmod +x ./helidon
# ls -al helidon
# ./helidon version

chmod +x env.sh

if [ $MODE == "GIT " ]; then
  git clone $GIT_URL
  cp ../mode/git/* $REPOSITORY_NAME/.
elif [ -v REPOSITORY_NAME ]; then
  mkdir $REPOSITORY_NAME
else 
  export REPOSITORY_NAME=output
  mkdir $REPOSITORY_NAME
fi
cd ./$REPOSITORY_NAME

cp -r ../basis/* .
mv ../env.sh .

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
  echo `cat env.sh | grep __TO_FILL__` >> README.md
  echo >> README.md
fi
echo "- Run:" >> README.md
if [ "$MODE" == "CLI" ]; then
echo "  cd output" >> README.md
fi
echo "  ./build.sh" >> README.md

#-- Insfrastruture As Code --------------------------------------------------

# Default state local
cp -r ../option/infra_as_code/terraform_local/* terraform/.
if [ "$TF_VAR_infra_as_code" == "resource_manager" ]; then
  cp -r ../option/infra_as_code/resource_manager/* terraform/.
elif [ "$TF_VAR_infra_as_code" == "terraform_object_storage" ]; then
  cp -r ../option/infra_as_code/terraform_object_storage/* terraform/.
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
  cp -r ../option/app_src/fn/fn_common/* app_src/.
fi  

# Generic version for Oracle DB
if [ -d "../option/app_src/$APP" ]; then
  cp -r ../option/app_src/$APP/* app_src/.
fi

# Overwrite the generic version (ex for mysql)
if [ -d "../option/app_src/$APP_DB" ]; then
  cp -r ../option/app_src/$APP_DB/* app_src/.
fi


#-- User Interface ----------------------------------------------------------

if [[ $TF_VAR_ui_strategy == "None" ]]; then
  echo "No UI"
else
  mkdir ui_src
  UI=`echo "$TF_VAR_ui_strategy" | awk '{print tolower($0)}'`
  # html is the base
  cp ../option/ui_src/html/* ui_src/.
  cp -r ../option/ui_src/$UI/* ui_src/.
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
  mkdir oke 
  cp -r ../option/oke/* oke/.

  if [ -f app_src/ingress-app.yaml ]; then
    mv app_src/ingress-app.yaml oke/.
  fi

  sed -i "s&##PREFIX##&${TF_VAR_prefix}&" app_src/app.yaml 
  sed -i "s&##PREFIX##&${TF_VAR_prefix}&" ui_src/ui.yaml
  sed -i "s&##PREFIX##&${TF_VAR_prefix}&" oke/ingress-app.yaml 
  sed -i "s&##PREFIX##&${TF_VAR_prefix}&" oke/ingress-ui.yaml
elif [[ $TF_VAR_deploy_strategy == "compute" ]]; then
  cp_terraform compute.tf
  mkdir compute 
  cp ../option/compute/* compute/.
elif [[ $TF_VAR_deploy_strategy == "function" ]]; then
  cp_terraform function.tf 
  if [ "$TF_VAR_language" == "ords" ]; then
    APIGW_APPEND=apigw_ords_append.tf
  else 
    APIGW_APPEND=apigw_append.tf
  fi

  if [ -v TF_VAR_apigw_ocid ]; then
    cp_terraform apigw_existing.tf $APIGW_APPEND
  else
    cp_terraform apigw.tf $APIGW_APPEND
  fi
fi

#-- Bastion -----------------------------------------------------------------

if [ -v TF_VAR_bastion_ocid ]; then
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
  mv app_src/oracle.sql db_src/.
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
  cd $SCRIPT_DIR
  mkdir -p zip/$REPOSITORY_NAME
  mv $REPOSITORY_NAME zip/$REPOSITORY_NAME/$TF_VAR_prefix
  cd zip/$REPOSITORY_NAME
  zip -r ../$REPOSITORY_NAME.zip $TF_VAR_prefix
else
  echo
  cat README.md
fi

  
