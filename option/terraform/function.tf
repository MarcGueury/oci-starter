variable function_image_uri {}

resource "oci_functions_application" "starter_application" {
  #Required
  compartment_id = var.compartment_ocid
  display_name   = "starter-application"
  subnet_ids     = [oci_core_subnet.starter_subnet.id]

  image_policy_config {
    #Required
    is_policy_enabled = false
  }
}

resource "oci_functions_function" "function" {
  #Required
  application_id = oci_functions_application.starter_application.id
  display_name   = "function"
  image          = var.function_image_uri
  memory_in_mbs  = "2048"

  #Optional
  timeout_in_seconds = "300"
}

resource oci_apigateway_gateway starter_apigw {
  compartment_id = var.compartment_ocid
  display_name  = "${var.prefix}-apigw"
  endpoint_type = "PUBLIC"
  subnet_id = oci_core_subnet.starter_subnet.id 
}

output api {
   value=local.APIGW_API_URL
}

resource oci_apigateway_deployment starter_deployment {
  compartment_id = var.compartment_ocid
  display_name = "starter_deployment"
  gateway_id  = oci_apigateway_gateway.starter_apigw.id
  path_prefix = "/function"
  specification {
    logging_policies {
      #access_log = <<Optional value not found in discovery>>
      # execution_log {
      #   is_enabled = "true"
      #  log_level  = "INFO"
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
        FUNCTION !!
        XXXXX url  = local.APIGW_API_URL
      }
      methods = [
        "ANY",
      ]
      path = "/search"
    }
  }
}
