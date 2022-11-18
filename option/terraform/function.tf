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

resource "oci_logging_log_group" "starter_log_group" {
  #Required
  compartment_id = var.compartment_ocid
  display_name   = "${var.prefix}-log-group"
}

resource oci_logging_log export_starter_fn_application_invoke {
  configuration {
    compartment_id = var.compartment_ocid
    source {
      category    = "invoke"
      resource    = local.fnapp_ocid
      service     = "functions"
      source_type = "OCISERVICE"
    }
  }
  display_name = "starter-fn-application-invoke"
  is_enabled         = "true"
  log_group_id       = oci_logging_log_group.starter_log_group.id
  log_type           = "SERVICE"
  retention_duration = "30"
}

locals {
  fnapp_ocid = oci_functions_application.starter_fn_application.id
}