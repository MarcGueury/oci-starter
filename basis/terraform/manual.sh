if [ -f provider.manual ]; then
  mv provider.manual provider.tf
fi

. ../resource_manager_variables.sh
terraform init
terraform plan