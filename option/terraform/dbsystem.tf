variable "db_edition" {
  default = "ENTERPRISE_EDITION"
}

variable "n_character_set" {
  default = "AL16UTF16"
}

variable "character_set" {
  default = "AL32UTF8"
}

# BRING_YOUR_OWN_LICENSE or LICENSE_INCLUDED
variable license_model{
  default="BRING_YOUR_OWN_LICENSE"
}

resource "oci_database_db_system" "starter_dbsystem" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  database_edition    = var.db_edition

  db_home {
    database {
      admin_password = var.db_password
      db_name        = "${var.prefix}"
      pdb_name       = "PDB1"
    }

    // XXX The last version should be dynamic
    db_version   = "21.7.0.0"
    display_name = "${var.prefix}home"
  }

  db_system_options {
    storage_management = "LVM"
  }

  shape                   = "VM.Standard2.1"
  subnet_id               = data.oci_core_subnet.starter_subnet.id
  ssh_public_keys         = [var.ssh_public_key]
  display_name            = "${var.prefix}db"
  hostname                = "${var.prefix}db"
  data_storage_size_in_gb = "256"
  license_model           = var.license_model
  node_count              = 1
}

# Compatibility with db_existing.tf 
data "oci_database_db_homes" "starter_db_homes" {
  compartment_id = var.compartment_ocid
  db_system_id   = oci_database_db_system.starter_dbsystem.id
}
