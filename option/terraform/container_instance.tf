variable docker_image_ui {
    default=""
}

variable docker_image_app {
    default=""
}

resource "oci_identity_dynamic_group" "starter_ci_dyngroup" {
  # No prefix to share it between all container instances
  name           = "starter-ci-dyngroup"
  description    = "Starter - All Container Instances"
  compartment_id = var.tenancy_ocid
  matching_rule  = "ALL {resource.type='computecontainerinstance'}"
  freeform_tags = {
    "group" = local.group_name
    "app_prefix" = var.prefix
  }    
}

resource "oci_identity_policy" "starter-ci_policy" {
  name           = "starter-fn-policy"
  description    = "Container instance access to OCIR"
  compartment_id = var.tenancy_ocid
  statements = [
    "allow dynamic-group starter-ci-dyngroup to read repos in tenancy"
  ]
  freeform_tags = {
    "group" = local.group_name
    "app_prefix" = var.prefix
  }    
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
  state = "ACTIVE"
  vnics {
    display_name           = "${var.prefix}-ci"
    hostname_label         = "${var.prefix}-ci"
    is_public_ip_assigned  = "true"
    skip_source_dest_check = "true"
    subnet_id              = data.oci_core_subnet.starter_subnet.id
  }
  freeform_tags = {
    "group" = local.group_name
    "app_prefix" = var.prefix
  }    
}

locals {
  ci_private_ip = try(oci_container_instances_container_instance.starter_container_instance[0].vnics[0].private_ip, "")
}