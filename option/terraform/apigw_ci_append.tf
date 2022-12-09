resource "oci_apigateway_deployment" "starter_apigw_deployment" {
  count          = var.docker_image_ui == "" ? 0 : 1
  compartment_id = local.lz_appdev_cmp_ocid
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
      path    = "/app/{pathname*}"
      methods = [ "ANY" ]
      backend {
        type = "HTTP_BACKEND"
        url    = "http://${local.ci_private_ip}:8080/$${request.path[pathname]}"
      }
    }     
    routes {
      path    = "/{pathname*}"
      methods = [ "ANY" ]
      backend {
        type = "HTTP_BACKEND"
        url    = "http://${local.ci_private_ip}/$${request.path[pathname]}"
      }
    }
  }
}