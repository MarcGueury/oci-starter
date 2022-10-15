data "oci_database_databases" "starter_dbs" {
  compartment_id = var.compartment_ocid
  db_home_id     = data.oci_database_db_homes.starter_db_homes.db_homes.0.db_home_id
}

data "oci_database_pluggable_databases" "starter_pdbs" {
  database_id = data.oci_database_databases.starter_dbs.databases.0.id
}

locals {
  connect_string = data.oci_database_pluggable_databases.starter_pdbs.pluggable_databases.0.connection_strings.pdb_ip_default
  jdbc_url = format("jdbc:oracle:thin:@%s", local.connect_string)
}

output "jdbc_url" {
   value = local.jdbc_url
}
