variable "db_ocid" {}

data "oci_database_db_homes" "starter_db_homes" {
  compartment_id = local.lz_database_cmp_ocid
  db_system_id   = var.db_ocid
}
