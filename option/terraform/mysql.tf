resource "oci_mysql_mysql_db_system" "starter_mysql" {
  #Required
  admin_password      = var.db_password
  admin_username      = "admin"
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  configuration_id    = data.oci_mysql_mysql_configurations.test_mysql_configurations.configurations[0].id
  shape_name          = "MySQL.VM.Standard.E3.1.8GB"
  subnet_id           = data.oci_core_subnet.starter_subnet.id
}


data "oci_mysql_mysql_db_system" "starter_mysql" {
    #Required
    db_system_id = oci_mysql_mysql_db_system.starter_mysql.id
}