resource "oci_mysql_mysql_db_system" "starter_mysql" {
  display_name        = "${var.prefix}-mysql"

  admin_password      = var.db_password
  admin_username      = var.db_user
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  shape_name          = "MySQL.VM.Standard.E4.1.8GB"
  subnet_id           = data.oci_core_subnet.starter_subnet.id
}

# Compatibility with mysql_existing.tf 
data "oci_mysql_mysql_db_system" "starter_mysql" {
    #Required
    db_system_id = oci_mysql_mysql_db_system.starter_mysql.id
}

