variable docker_image_ui {
    default=""
}

variable docker_image_app {
    default=""
}

variable auth_token {
    default=""
}

resource oci_container_instances_container_instance starter_container_instance {
  count = var.docker_image_ui == "" ? 0 : 1
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = local.lz_appdev_cmp_ocid  
  container_restart_policy = "ALWAYS"
  containers {
    display_name = "app"
    image_url = var.docker_image_app
    is_resource_principal_disabled = "false"
    environment_variables = {
      "DB_URL" = local.db_url,
      "JDBC_URL" = local.jdbc_url,
      "DB_USER" = var.db_user,
      "DB_PASSWORD" = var.db_password,
      "SPRING_APPLICATION_JSON" = "{ \"db.info\": \"Java - SpringBoot\" }",
      "JAVAX_SQL_DATASOURCE_DS1_DATASOURCE_URL" = local.jdbc_url
    }    
  }
  containers {
    display_name = "ui"
    image_url = var.docker_image_ui
    is_resource_principal_disabled = "false"
  }  
  display_name = "${var.prefix}-ci"
  graceful_shutdown_timeout_in_seconds = "0"
  shape                                = "CI.Standard.E3.Flex"
  shape_config {
    memory_in_gbs = "4"
    ocpus         = "1"
  }
  image_pull_secrets {
      username = base64encode(local.ocir_username)
      password = base64encode(var.auth_token)
      registry_endpoint = local.ocir_docker_repository
      secret_type = "BASIC"
  }
  state = "ACTIVE"
  vnics {
    display_name           = "${var.prefix}-ci"
    hostname_label         = "${var.prefix}-ci"
    is_public_ip_assigned  = "true"
    skip_source_dest_check = "true"
    subnet_id              = data.oci_core_subnet.starter_subnet.id
  }
}

locals {
  ci_private_ip = try(oci_container_instances_container_instance.starter_container_instance[0].vnics[0].private_ip, "")
}