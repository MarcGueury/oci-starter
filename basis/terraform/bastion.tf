# Defines the number of instances to deploy
variable "instance_ocpus" {
  default = 1
}

variable "instance_shape_config_memory_in_gbs" {
  default = 8
}

resource "oci_core_instance" "starter_bastion" {

  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "${var.prefix}-bastion"
  shape               = "VM.Standard.E4.Flex"

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_shape_config_memory_in_gbs
  }

  create_vnic_details {
    subnet_id                 = data.oci_core_subnet.starter_subnet.id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "${var.prefix}-bastion"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oraclelinux.images.0.id
  }

  connection {
    agent       = false
    host        = oci_core_instance.starter_bastion.public_ip
    user        = "opc"
    private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "date"
    ]
  }
}

# Output the private and public IPs of the instance
output "bastion_private_ips" {
  value = [oci_core_instance.starter_bastion.*.private_ip]
}

output "bastion_public_ips" {
  value = [oci_core_instance.starter_bastion.*.public_ip]
}
