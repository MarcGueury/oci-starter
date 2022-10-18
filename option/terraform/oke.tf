variable "oke_shape" {
  default = "VM.Standard2.1"
}

variable "node_pool_node_config_details_size" {
    default = 1
}

variable "cluster_options_persistent_volume_config_defined_tags_value" {
  default = "value"
}

#----------------------------------------------------------------------------

data "oci_containerengine_cluster_option" "starter_cluster_option" {
  cluster_option_id = "all"
}

data "oci_containerengine_node_pool_option" "starter_node_pool_option" {
  node_pool_option_id = "all"
}

data "oci_identity_availability_domain" "ad1" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

data "oci_identity_availability_domain" "ad2" {
  compartment_id = var.tenancy_ocid
  ad_number      = 2
}

data "oci_core_images" "shape_specific_images" {
  #Required
  compartment_id = var.tenancy_ocid
  shape     = var.oke_shape
}

locals {
  all_images = "${data.oci_core_images.shape_specific_images.images}"
  all_sources = "${data.oci_containerengine_node_pool_option.starter_node_pool_option.sources}"
  compartment_images = [for image in local.all_images : image.id if length(regexall("Oracle-Linux-[0-9]*.[0-9]*-20[0-9]*",image.display_name)) > 0 ]
  oracle_linux_images = [for source in local.all_sources : source.image_id if length(regexall("Oracle-Linux-[0-9]*.[0-9]*-20[0-9]*",source.source_name)) > 0]
  image_id = tolist(setintersection( toset(local.compartment_images), toset(local.oracle_linux_images)))[0]
}

#----------------------------------------------------------------------------

resource "oci_core_subnet" "starter_lb_subnet1" {
  #Required
  availability_domain = data.oci_identity_availability_domain.ad1.name
  cidr_block          = "10.0.20.0/24"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.starter_vcn.id

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_vcn.starter_vcn.default_security_list_id]
  display_name      = "${var.prefix}-oke-lb-subnet1"
  route_table_id    = oci_core_vcn.starter_vcn.default_route_table_id
}

resource "oci_core_subnet" "starter_lb_subnet2" {
  #Required
  availability_domain = data.oci_identity_availability_domain.ad2.name
  cidr_block          = "10.0.21.0/24"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.starter_vcn.id
  display_name        = "${var.prefix}-oke-lb-subnet2"

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_vcn.starter_vcn.default_security_list_id]
  route_table_id    = oci_core_vcn.starter_vcn.default_route_table_id
}

resource "oci_core_subnet" "starter_nodepool_subnet" {
  #Required
  availability_domain = data.oci_identity_availability_domain.ad1.name
  cidr_block          = "10.0.22.0/24"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.starter_vcn.id

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_vcn.starter_vcn.default_security_list_id,oci_core_security_list.starter_security_list.id]
  display_name      = "${var.prefix}-oke-nodepool-subnet"
  route_table_id    = oci_core_vcn.starter_vcn.default_route_table_id
}

resource "oci_core_subnet" "starter_api_subnet" {
  #Required
  cidr_block          = "10.0.23.0/24"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.starter_vcn.id

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_vcn.starter_vcn.default_security_list_id,oci_core_security_list.starter_security_list.id]
  display_name      = "${var.prefix}-oke-api-subnet"
  route_table_id    = oci_core_vcn.starter_vcn.default_route_table_id
}

#----------------------------------------------------------------------------

resource "oci_containerengine_cluster" "starter_oke" {
  #Required
  compartment_id     = var.compartment_ocid
  kubernetes_version = data.oci_containerengine_cluster_option.starter_cluster_option.kubernetes_versions[length(data.oci_containerengine_cluster_option.starter_cluster_option.kubernetes_versions)-1]
  name               = "${var.prefix}-oke"
  vcn_id             = oci_core_vcn.starter_vcn.id

  #Optional
  endpoint_config {
    subnet_id             = oci_core_subnet.starter_api_subnet.id
    is_public_ip_enabled  = "true"
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.starter_lb_subnet1.id, oci_core_subnet.starter_lb_subnet2.id]

    #Optional
    add_ons {
      #Optional
      is_kubernetes_dashboard_enabled = "true"
      is_tiller_enabled               = "true"
    }

    admission_controller_options {
      #Optional
      is_pod_security_policy_enabled = true
    }

    kubernetes_network_config {
      #Optional
      pods_cidr     = "10.1.0.0/16"
      services_cidr = "10.2.0.0/16"
    }
  }
}

resource "oci_containerengine_node_pool" "starter_node_pool" {
  #Required
  cluster_id         = oci_containerengine_cluster.starter_oke.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = data.oci_containerengine_node_pool_option.starter_node_pool_option.kubernetes_versions[length(data.oci_containerengine_node_pool_option.starter_node_pool_option.kubernetes_versions)-1]
  name               = "${var.prefix}-pool"
  node_shape         = var.oke_shape

  node_source_details {
    #Required
    image_id    = local.image_id
    source_type = "IMAGE"
  }

  node_config_details {
    #Required
    placement_configs {
      #Required
      availability_domain = data.oci_identity_availability_domain.ad1.name
      subnet_id           = oci_core_subnet.starter_nodepool_subnet.id
      #optional
      fault_domains = ["FAULT-DOMAIN-1", "FAULT-DOMAIN-3"]
    }
    size = var.node_pool_node_config_details_size
  }

  ssh_public_key      = var.ssh_public_key
}

#----------------------------------------------------------------------------

output "node_pool" {
  value = {
    id                 = oci_containerengine_node_pool.starter_node_pool.id
    kubernetes_version = oci_containerengine_node_pool.starter_node_pool.kubernetes_version
    name               = oci_containerengine_node_pool.starter_node_pool.name
    subnet_ids         = oci_containerengine_node_pool.starter_node_pool.subnet_ids
  }
}

#----------------------------------------------------------------------------

locals {
  oke_ocid = oci_containerengine_cluster.starter_oke.id
}