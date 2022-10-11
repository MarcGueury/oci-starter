// ------------------------ Autonomous database -----------------------------
data "oci_database_autonomous_database" "starter_atp" {
  #Required
  id                       = var.atp_ocid
}