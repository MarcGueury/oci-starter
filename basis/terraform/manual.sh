if [ -f provider.manual ]; then
  mv provider.manual provider.tf
fi

. ../bin/env_pre_terraform.sh
terraform init
terraform plan