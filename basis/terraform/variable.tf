variable "tenancy_ocid" {}
variable "region" {}
variable "compartment_ocid" {}
variable "ssh_public_key" {}
variable "ssh_private_key" {}

# Prefix
variable "service_name" {
  default = "starter"
}

# JAVA_VERSION
variable "java_version" {
  default = "17"
}

variable "db_user" {}
variable db_password{}