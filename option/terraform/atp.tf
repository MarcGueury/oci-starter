# BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED
variable license_model{
  default="BRING_YOUR_OWN_LICENSE"
}

resource "oci_database_autonomous_database" "starter_atp" {
  #Required
  admin_password           = var.db_password
  compartment_id           = var.compartment_ocid
  cpu_core_count           = "1"
  data_storage_size_in_tbs = "1"
  db_name                  = "${var.prefix}atp"

  #Optional
  db_workload                                    = "OLTP"
  display_name                                   = "${var.prefix}atp"
  is_auto_scaling_enabled                        = "false"
  license_model                                  = var.license_model
  is_preview_version_with_service_terms_accepted = "false"
#  whitelisted_ips                                = [ data.oci_core_vcn.starter_vcn.id ]
  whitelisted_ips                                = [ "0.0.0.0/0" ]
  is_mtls_connection_required                    = false
}

# Compatibility with atp_existing.tf 
data "oci_database_autonomous_database" "starter_atp" {
  #Required
  id                       = oci_database_autonomous_database.starter_atp.id
}