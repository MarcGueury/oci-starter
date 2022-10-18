variable "cluster_options_add_ons_is_kubernetes_dashboard_enabled" {
  default = true
}

variable "cluster_options_add_ons_is_tiller_enabled" {
  default = true
}

variable "cluster_options_kubernetes_network_config_pods_cidr" {
  default = "10.1.0.0/16"
}

variable "cluster_options_kubernetes_network_config_services_cidr" {
  default = "10.2.0.0/16"
}

variable "node_pool_boot_volume_size_in_gbs" {
  default = "60"
}

variable "oke_shape" {
  default = "VM.Standard.E4.Flex"
}
 
#------------------------------------------------------------------------------------

data "oci_identity_availability_domain" "ad1" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

data "oci_identity_availability_domain" "ad2" {
  compartment_id = var.tenancy_ocid
  ad_number      = 2
}

data "oci_containerengine_cluster_option" "starter_cluster_option" {
  cluster_option_id = "all"
}

data "oci_containerengine_node_pool_option" "starter_node_pool_option" {
  node_pool_option_id = "all"
}

data "oci_core_images" "shape_specific_images" {
  #Required
  compartment_id = var.tenancy_ocid
  shape = var.oke_shape
}

locals {
  all_images = "${data.oci_core_images.shape_specific_images.images}"
  all_sources = "${data.oci_containerengine_node_pool_option.starter_node_pool_option.sources}"
  compartment_images = [for image in local.all_images : image.id if length(regexall("Oracle-Linux-[0-9]*.[0-9]*-20[0-9]*",image.display_name)) > 0 ]
  oracle_linux_images = [for source in local.all_sources : source.image_id if length(regexall("Oracle-Linux-[0-9]*.[0-9]*-20[0-9]*",source.source_name)) > 0]
  image_id = tolist(setintersection( toset(local.compartment_images), toset(local.oracle_linux_images)))[0]
}

output "cluster_kubernetes_versions" {
  value = [data.oci_containerengine_cluster_option.starter_cluster_option.kubernetes_versions]
}

output "node_pool_kubernetes_version" {
  value = [data.oci_containerengine_node_pool_option.starter_node_pool_option.kubernetes_versions]
}

output "node_pool_image_id" {
  value = tolist(setintersection( toset(local.compartment_images), toset(local.oracle_linux_images)))
}

output "all_sources" {
  value = data.oci_containerengine_node_pool_option.starter_node_pool_option.sources
}


#------------------------------------------------------------------------------------

resource "oci_core_subnet" "clusterSubnet_1" {
  #Required
  availability_domain = data.oci_identity_availability_domain.ad1.name
  cidr_block          = "10.0.20.0/24"
  compartment_id      = var.compartment_ocid
  vcn_id              = data.oci_core_vcn.starter_vcn.id

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_vcn.starter_vcn.default_security_list_id]
  display_name      = "tfSubNet1ForClusters"
  route_table_id    = oci_core_vcn.starter_vcn.default_route_table_id
}

resource "oci_core_subnet" "clusterSubnet_2" {
  #Required
  availability_domain = data.oci_identity_availability_domain.ad2.name
  cidr_block          = "10.0.21.0/24"
  compartment_id      = var.compartment_ocid
  vcn_id              = data.oci_core_vcn.starter_vcn.id
  display_name        = "tfSubNet1ForClusters"

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_vcn.starter_vcn.default_security_list_id]
  route_table_id    = oci_core_vcn.starter_vcn.default_route_table_id
}

resource "oci_core_subnet" "cluster_regional_subnet" {
  #Required
  cidr_block     = "10.0.26.0/24"
  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_vcn.starter_vcn.id

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_vcn.starter_vcn.default_security_list_id]
  display_name      = "clusterRegionalSubnet"
  route_table_id    = oci_core_vcn.starter_vcn.default_route_table_id
}

resource "oci_core_subnet" "node_pool_regional_subnet_1" {
  #Required
  cidr_block     = "10.0.24.0/24"
  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_vcn.starter_vcn.id

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_vcn.starter_vcn.default_security_list_id]
  display_name      = "nodePoolRegionalSubnet1"
  route_table_id    = oci_core_vcn.starter_vcn.default_route_table_id
}

resource "oci_core_subnet" "node_pool_regional_subnet_2" {
  #Required
  cidr_block     = "10.0.25.0/24"
  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_vcn.starter_vcn.id

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = [oci_core_vcn.starter_vcn.default_security_list_id]
  display_name      = "nodePoolRegionalSubnet2"
  route_table_id    = oci_core_vcn.starter_vcn.default_route_table_id
}
#------------------------------------------------------------------------------------

resource "oci_containerengine_cluster" "starter_cluster" {
  #Required
  compartment_id     = var.compartment_ocid
  kubernetes_version = data.oci_containerengine_cluster_option.starter_cluster_option.kubernetes_versions[length(data.oci_containerengine_cluster_option.starter_cluster_option.kubernetes_versions)-1]
  name               = "${var.prefix}-oke"
  vcn_id             = data.oci_core_vcn.starter_vcn.id

  #Optional
  endpoint_config {
    subnet_id             = oci_core_subnet.cluster_regional_subnet.id
    is_public_ip_enabled  = "true"
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.clusterSubnet_1.id, oci_core_subnet.clusterSubnet_2.id]

    #Optional
    add_ons {
      #Optional
      is_kubernetes_dashboard_enabled = var.cluster_options_add_ons_is_kubernetes_dashboard_enabled
      is_tiller_enabled               = var.cluster_options_add_ons_is_tiller_enabled
    }

    kubernetes_network_config {
      #Optional
      pods_cidr     = var.cluster_options_kubernetes_network_config_pods_cidr
      services_cidr = var.cluster_options_kubernetes_network_config_services_cidr
    }
  }
}

resource "oci_containerengine_node_pool" "starter_node_pool" {
  #Required
  cluster_id         = oci_containerengine_cluster.starter_cluster.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = data.oci_containerengine_node_pool_option.starter_node_pool_option.kubernetes_versions[length(data.oci_containerengine_node_pool_option.starter_node_pool_option.kubernetes_versions)-1]
  name               = "${var.prefix}-pool"
  node_shape         = var.oke_shape

  node_source_details {
    #Required
    image_id    = local.oracle_linux_images.0
    source_type = "IMAGE"

    #Optional
    boot_volume_size_in_gbs = var.node_pool_boot_volume_size_in_gbs
  }

  ssh_public_key = var.ssh_public_key

  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domain.ad2.name
      subnet_id           = oci_core_subnet.node_pool_regional_subnet_2.id
    }

    placement_configs {
      availability_domain = data.oci_identity_availability_domain.ad1.name
      subnet_id           = oci_core_subnet.node_pool_regional_subnet_1.id
    }
    size = 2
  }
}

output "cluster" {
  value = {
    id                 = oci_containerengine_cluster.starter_cluster.id
    kubernetes_version = oci_containerengine_cluster.starter_cluster.kubernetes_version
    name               = oci_containerengine_cluster.starter_cluster.name
  }
}

output "node_pool" {
  value = {
    id                 = oci_containerengine_node_pool.starter_node_pool.id
    kubernetes_version = oci_containerengine_node_pool.starter_node_pool.kubernetes_version
    name               = oci_containerengine_node_pool.starter_node_pool.name
  }
}

locals {
  oke_ocid = oci_containerengine_cluster.starter_cluster.id
}