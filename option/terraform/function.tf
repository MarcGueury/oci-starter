variable fn_image {default=""}
variable fn_db_url {default=""}


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
  count = var.fn_image==""?0:1
  application_id = oci_functions_application.starter_fn_application.id
  display_name   = "${var.prefix}-fn-function"
  image          = var.fn_image
  memory_in_mbs  = "2048"
  config = {
    DB_URL = var.fn_db_url,
    DB_USER = var.db_user,
    DB_PASSWORD = var.db_password,
  }
  #Optional
  timeout_in_seconds = "300"
  trace_config {
    is_enabled = true
  }
}

resource oci_apigateway_deployment starter_apigw_deployment {
  count = var.fn_image==""?0:1
  compartment_id = var.compartment_ocid
  display_name = "${var.prefix}-apigw-deployment"
  gateway_id  = local.apigw_ocid
  path_prefix = "/app"
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
      backend {
        connect_timeout_in_seconds = "60"
        is_ssl_verify_disabled  = "true"
        read_timeout_in_seconds = "10"
        send_timeout_in_seconds = "10"
        type = "ORACLE_FUNCTIONS_BACKEND"
        function_id = oci_functions_function.starter_fn_function[0].id
      }
      methods = [
        "ANY",
      ]
      path = "/dept"
    }
  }
}

output fn_url {
  value= join("", oci_apigateway_deployment.starter_apigw_deployment.*.endpoint )
}

resource "oci_identity_policy" "starter_fn_policy" {
  provider       = oci.home_region
  name           = "${var.prefix}-fn-policy"
  description    = "APIGW access Function"
  compartment_id = var.compartment_ocid
  statements = [
    "ALLOW any-user to use functions-family in compartment id ${var.compartment_ocid} where ALL {request.principal.type= 'ApiGateway', request.resource.compartment.id = '${var.compartment_ocid}'}"
  ]
}
