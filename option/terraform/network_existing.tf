
variable "vcn_ocid" {}
variable "subnet_ocid" {}

data "oci_core_vcn" "starter_vcn" {
  vcn_id = var.vcn_ocid
}

data "oci_core_subnet" "starter_subnet" {
  subnet_id = var.subnet_ocid
}


