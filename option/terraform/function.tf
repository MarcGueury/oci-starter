variable "fn_image" { default = "" }
variable "fn_db_url" { default = "" }


resource "oci_logging_log_group" "starter_log_group" {
  #Required
  compartment_id = var.compartment_ocid
  display_name   = "${var.prefix}-log-group"
}


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

resource "oci_apigateway_deployment" "starter_apigw_deployment" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.prefix}-apigw-deployment"
  gateway_id     = local.apigw_ocid
  path_prefix    = "/${var.prefix}"
  specification {
    logging_policies {
      access_log {
        is_enabled = true
      }
      execution_log {
        #Optional
        is_enabled = true
      }
    }
    routes {
      path    = "/{pathname*}"
      methods = [ "ANY" ]
      backend {
        type = "DYNAMIC_ROUTING_BACKEND"
        selection_source {
          type     = "SINGLE"
          selector = "request.path[pathname]"
        }
        routing_backends {
          key {
            type   = "ANY_OF"
            values = ["app/info"]
            name   = "info"
          }
          backend {
            type   = "STOCK_RESPONSE_BACKEND"
            body   = "FUNCTION"
            status = 200
          }
        }
      }
    }
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

variable "namespace" {}

resource "oci_objectstorage_bucket" "starter_bucket" {
  compartment_id = var.compartment_ocid
  namespace      = var.namespace
  name           = "${var.prefix}-public-bucket"
  access_type    = "ObjectReadWithoutList"
}

