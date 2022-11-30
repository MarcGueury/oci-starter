resource oci_apigateway_gateway starter_apigw {
  compartment_id = local.lz_appdev_cmp_ocid
  display_name  = "${var.prefix}-apigw"
  endpoint_type = "PUBLIC"
  subnet_id = data.oci_core_subnet.starter_subnet.id
}

locals {
  apigw_ocid = oci_apigateway_gateway.starter_apigw.id
}
