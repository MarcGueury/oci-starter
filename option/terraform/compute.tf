# Defines the number of instances to deploy
resource "oci_core_instance" "starter_instance" {

  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "${var.prefix}-instance"
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
    hostname_label            = "${var.prefix}-instance"
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
    host        = oci_core_instance.starter_instance.public_ip
    user        = "opc"
    private_key = var.ssh_private_key
  }

  provisioner "file" {
    source      = "../compute"
    destination = "."
  }

  provisioner "remote-exec" {
    on_failure = continue
    inline = [
      "export TF_VAR_java_version=${var.java_version}",
      "export JDBC_URL='${local.jdbc_url}'",
      "mv compute/* .",
      "rmdir compute",
      "bash compute_bootstrap.sh > compute_bootstrap.log 2>&1"
    ]
  }
}

# Output the private and public IPs of the instance
output "instance_private_ips" {
  value = [oci_core_instance.starter_instance.private_ip]
}

output "instance_public_ips" {
  value = [oci_core_instance.starter_instance.public_ip]
}

output "rest_url" {
  value = format("http://%s:8080/dept", oci_core_instance.starter_instance.public_ip)
}

output "ui_url" {
  value = format("http://%s/", oci_core_instance.starter_instance.public_ip)
}

