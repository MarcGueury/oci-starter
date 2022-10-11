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
}

resource "null_resource" "starter_bastion_install" {
    depends_on = [oci_core_instance.starter_bastion, local.connect_string ]

    provisioner "file" {
      connection {
        agent       = false
        host        = "${oci_core_instance.starter_bastion.public_ip}"
        user        = "opc"
        private_key = var.ssh_private_key
      }
      source = "../db_src"
      destination = "db_src"
    }

    provisioner "remote-exec" {
      on_failure = continue
      connection {
        agent       = false
        host        = "${oci_core_instance.starter_bastion.public_ip}"
        user        = "opc"
        private_key = var.ssh_private_key
      }

      inline = [
        "export DB_USER=${var.db_user}",
        "export DB_PASSWORD='${var.db_password}'",
        "export DB_URL='${local.connect_string}'",
        "bash db_src/db_init.sh > db_src/db_init.log 2>&1"
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