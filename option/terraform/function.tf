variable fn_image {default=""}
variable fn_config {default=""}


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
  count = var.function_image==""?0:1
  application_id = oci_functions_application.starter_fn_application.id
  display_name   = "${var.prefix}-fn-function"
  image          = var.fn_image
  memory_in_mbs  = "2048"
  config         = var.fn_config

  #Optional
  timeout_in_seconds = "300"
  trace_config {
    is_enabled = true
  }
}

resource oci_apigateway_deployment starter_apigw_deployment {
  count = var.function_image==""?0:1
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
    request_policies {
      mutual_tls {
        allowed_sans = [
        ]
        is_verified_certificate_required = "false"
      }
    }
    routes {
      backend {
        connect_timeout_in_seconds = "60"
        is_ssl_verify_disabled  = "true"
        read_timeout_in_seconds = "10"
        send_timeout_in_seconds = "10"
        type = "HTTP_BACKEND"
        // XXXXXX FUNCTION !!!
        url  = oci_functions_function.starter_fn_function[0].invoke_endpoint
      }
      methods = [
        "ANY",
      ]
      path = "/dept"
    }
  }
}

output fn_url {
  value= var.function_image==""?"":concat( oci_apigateway_deployment.starter_apigw_deployment[0].endpoint,"/dept" )
}
