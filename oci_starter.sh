title() {
    echo "-- $1 --------------------------------------------------"
}

todo() {
    echo "-- TODO ---"
}

cp_terraform() {
    echo "cp_terraform $1"
    cp ../option/terraform/$1 terraform/.
}

cp_dir_db_src() {
    echo "cp_terraform $1"
    cp ../option/db_src/$1/* db_src/.
}

title oci_starter.sh 

if [ "$#" -eq 3 ]; then
  export MODE=GIT
  export GIT_URL=$1
  export REPOSITORY_NAME=$2
  export OCI_USERNAME=$3
  echo GIT_URL=$GIT_URL
else
  export MODE=CLI
fi  
echo MODE=$MODE

title Command
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

chmod +x resource_manager_variables.sh
cat resource_manager_variables.sh

if [ $MODE == "GIT " ]; then
  git clone $GIT_URL
else 
  export REPOSITORY_NAME=output
  mkdir $REPOSITORY_NAME
fi
cd ./$REPOSITORY_NAME

cp -r ../basis/* .
cp ../resource_manager_variables.sh .

#-- APP ---------------------------------------------------------------------

APP_LANG=`echo "$TF_VAR_language" | awk '{print tolower($0)}'`
APP_FRAMEWORK=`echo "$TF_VAR_java_framework" | awk '{print tolower($0)}'`

case $TF_VAR_db_strategy in

"Autonomous Transaction Processing Database")
    APP_DB="oracle"
    ;;

"Database System")
    APP_DB="oracle"
    ;;

"MySQL")
    APP_DB="mysql"
esac

APP=${APP_LANG}_${APP_FRAMEWORK}_${APP_DB}
echo APP=$APP
mkdir app_src
mkdir db_src
if [ -d "../option/app_src/$APP" ]; then
  cp -r ../option/app_src/$APP/* app_src/.
else
  todo
fi

#-- User Interface ----------------------------------------------------------

if [[ $TF_VAR_ui_strategy == "None" ]]; then
  echo "No UI"
else
  mkdir ui_src
  UI=`echo "$TF_VAR_ui_strategy" | awk '{print tolower($0)}'`
  cp -r ../option/ui_src/$UI/* ui_src/.
fi

#-- Network -----------------------------------------------------------------

if [[ $TF_VAR_vnc_strategy == "Create New VCN" ]]; then
  cp_terraform network.tf 
else
  cp_terraform network_existing.tf 
fi

#-- Deployment --------------------------------------------------------------
if [[ $TF_VAR_deploy_strategy == "Kubernetes" ]]; then
  if [[ $TF_VAR_kubernetes_strategy == "OKE" ]]; then
    if [[ $TF_VAR_oke_strategy == "Create New OKE" ]]; then
      cp_terraform oke.tf 
    else
      cp_terraform oke_existing.tf 
    fi   
  fi
elif [[ $TF_VAR_deploy_strategy == "Virtual Machine" ]]; then
  cp_terraform compute.tf
  mkdir compute 
  if [[ $TF_VAR_language == "Java" ]]; then
    cp ../option/app_src/compute/compute_java_bootstrap.sh compute/compute_bootstrap.sh
  fi
  # XX Other language missing
elif [[ $TF_VAR_deploy_strategy == "Function" ]]; then
  cp_terraform function.tf 
fi

#-- Database ----------------------------------------------------------------
if [[ $TF_VAR_db_strategy == "Autonomous Transaction Processing Database" ]]; then
  cp_terraform atp_common.tf
  cp_dir_db_src oracle
  if [[ $TF_VAR_db_existing_strategy == "Create New DB" ]]; then
    cp_terraform atp.tf 
  else
    cp_terraform atp_existing.tf
  fi   
elif [[ $TF_VAR_db_strategy == "Database System" ]]; then
  cp_dir_db_src oracle
  if [[ $TF_VAR_db_existing_strategy == "Create New DB" ]]; then
    cp_terraform dbsystem.tf 
  else
    cp_terraform dbsystem_existing.tf 
  fi   
elif [[ $TF_VAR_db_strategy == "MySQL" ]]; then  
  cp_dir_db_src mysql
  if [[ $TF_VAR_db_existing_strategy == "Create New DB" ]]; then
    cp_terraform mysql.tf 
  else
    cp_terraform mysql_existing.tf
  fi   
fi

if [ $MODE == "GIT " ]; then
  #-- Commit in devops git ----------------------------------------------------
  git config --local user.email "test@example.com"
  git config --local user.name "${OCI_USERNAME}"
  git add .
  git commit -m "added latest files"
  git push origin main
else
  title "Done"
  echo Directory $REPOSITORY_NAME created.
fi

  
