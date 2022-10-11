# --- Network ---
resource "oci_core_vcn" "starter_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "${var.prefix}-vcn"
  dns_label      = "${var.prefix}vcn"
}

resource "oci_core_internet_gateway" "starter_internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.prefix}-internet-gateway"
  vcn_id         = oci_core_vcn.starter_vcn.id
}

resource "oci_core_default_route_table" "default_route_table" {
  manage_default_resource_id = oci_core_vcn.starter_vcn.default_route_table_id
  display_name               = "DefaultRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.starter_internet_gateway.id
  }
}

#  XXXXXX split Private / Public network
resource "oci_core_subnet" "starter_subnet" {
  cidr_block        = "10.0.1.0/24"
  display_name      = "${var.prefix}-subnet"
  dns_label         = "${var.prefix}sub"
  security_list_ids = [oci_core_vcn.starter_vcn.default_security_list_id, oci_core_security_list.starter_security_list.id]
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.starter_vcn.id
  route_table_id    = oci_core_vcn.starter_vcn.default_route_table_id
  dhcp_options_id   = oci_core_vcn.starter_vcn.default_dhcp_options_id
}

resource "oci_core_security_list" "starter_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.starter_vcn.id
  display_name   = "${var.prefix}-security-list"

  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 443
      max = 443
    }
  }

  // XXXXXX 0.0.0.0/0 ??
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 8080
      max = 8080
    }
  }  

  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "10.0.0.0/8"
    stateless = false

    tcp_options {
      min = 1521
      max = 1521
    }
  }  
}

# Compatibility with network_existing.tf
data "oci_core_vcn" "starter_vcn" {
  vcn_id = oci_core_vcn.starter_vcn.id
}

data "oci_core_subnet" "starter_subnet" {
  subnet_id = oci_core_subnet.starter_subnet.id
}
