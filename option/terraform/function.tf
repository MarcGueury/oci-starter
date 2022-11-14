variable "fn_image" { default = "" }
variable "fn_db_url" { default = "" }

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

resource "oci_functions_function" "starter_fn_function" {
  #Required
  count          = var.fn_image == "" ? 0 : 1
  application_id = oci_functions_application.starter_fn_application.id
  display_name   = "${var.prefix}-fn-function"
  image          = var.fn_image
  memory_in_mbs  = "2048"
  config = {
    DB_URL      = var.fn_db_url,
    DB_USER     = var.db_user,
    DB_PASSWORD = var.db_password,
  }
  #Optional
  timeout_in_seconds = "300"
  trace_config {
    is_enabled = true
  }
}

output "fn_url" {
  value = join("", oci_apigateway_deployment.starter_apigw_deployment.*.endpoint)
}

resource "oci_identity_policy" "starter_fn_policy" {
  name           = "${var.prefix}-fn-policy"
  description    = "APIGW access Function"
  compartment_id = var.compartment_ocid
  statements = [
    "ALLOW any-user to use functions-family in compartment id ${var.compartment_ocid} where ALL {request.principal.type= 'ApiGateway', request.resource.compartment.id = '${var.compartment_ocid}'}"
  ]
}

#-- Object Storage ----------------------------------------------------------

variable "namespace" {}

resource "oci_objectstorage_bucket" "starter_bucket" {
  compartment_id = var.compartment_ocid
  namespace      = var.namespace
  name           = "${var.prefix}-public-bucket"
  access_type    = "ObjectReadWithoutList"
}

locals {
  bucket_url = "https://objectstorage.${var.region}.oraclecloud.com/n/${var.namespace}/b/${var.prefix}-public-bucket/o"
}

#-- Log ---------------------------------------------------------------------
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
      resource    = oci_functions_application.starter-fn-application.id
      service     = "functions"
      source_type = "OCISERVICE"
    }
  }
  display_name = "starter-fn-application-invoke"
  is_enabled         = "true"
  log_group_id       = oci_logging_log_group.starter-log-group.id
  log_type           = "SERVICE"
  retention_duration = "30"
}