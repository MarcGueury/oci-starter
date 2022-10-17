variable "db_ocid" {}

data "oci_database_db_homes" "starter_db_homes" {
  compartment_id = var.compartment_ocid
  db_system_id   = var.db_ocid
}
