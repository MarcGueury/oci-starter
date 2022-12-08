variable docker_image_ui {
    default=""
}

variable docker_image_app {
    default=""
}

variable auth_token {
    default=""
}

resource "oci_container_instances_container_instance" "starter_container_instance" {
  #Required
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = local.lz_appdev_cmp_ocid  
  count               = var.docker_image_ui == "" ? 0 : 1
  display_name        = "starter-ci"

  containers {
    #Required
    image_url         = "busybox"
/*
    imagePullSecrets = {
      username = base64encode(local.ocir_username),
      password = base64encode(var.auth_token),
      registryEndpoint = local.ocir_docker_repository,
      secretType = "BASIC"
    }
*/
    #Optional
    additional_capabilities = [
      "CAP_NET_ADMIN"]
    display_name = "starter-ui"
    environment_variables = {
      "environment" = "variable"
    }
    is_resource_principal_disabled = "false"
  }
  shape = "CI.Standard.E4.Flex"

  shape_config {
    memory_in_gbs = "4"
    ocpus         = "1"
  }

  vnics {
    #Required
    subnet_id = data.oci_core_subnet.starter_subnet.id

    #Optional
    display_name = "starter_ci_primary_vnic"
    hostname_label = "starter-ci"
    is_public_ip_assigned = "true"
    nsg_ids = []
  }

/*
  lifecycle {
    ignore_changes = [
      "defined_tags"]
  }
*/  
  state           = "ACTIVE"
}