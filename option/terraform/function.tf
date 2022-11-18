resource "oci_functions_application" "starter_fn_application" {
  #Required
  compartment_id = var.compartment_ocid
  display_name   = "${var.prefix}-fn-application"
  subnet_ids     = [data.oci_core_subnet.starter_subnet.id]

  image_policy_config {
    #Required
    is_policy_enabled = false
  }
}
