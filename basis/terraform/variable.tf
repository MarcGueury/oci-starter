variable tenancy_ocid {}
variable region {}
variable compartment_ocid {}
variable ssh_public_key {}
variable ssh_private_key {}

# Prefix
variable prefix { default = "starter" }

# JAVA
variable language { default = "java" }
variable java_version { default = "17" }

variable db_user {}
variable db_password{}

# Compute Instance size
variable "instance_ocpus" { default = 1 }
variable "instance_shape_config_memory_in_gbs" { default = 8 }
