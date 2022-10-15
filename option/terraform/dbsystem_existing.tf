# Compatibility with db_existing.tf 
data "oci_database_db_homes" "starter_db_homes" {
  compartment_id = var.compartment_ocid
  db_system_id   = var.atp_ocid
}
