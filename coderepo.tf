## Copyright (c) 2022, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_devops_repository" "test_repository" {
  #Required
  name       = "repository"
  project_id = oci_devops_project.test_project.id

  #Optional
  default_branch = "main"
  description    = "repository"

  repository_type = "HOSTED"
}

resource "null_resource" "clonerepo" {

  depends_on = [oci_devops_project.test_project, oci_devops_repository.test_repository]

  provisioner "local-exec" {
    command = <<-EOT
      echo '(1) TEST'
      echo '
      export TF_VAR_tenancy_ocid=${var.tenancy_ocid}
      export TF_VAR_region=${var.region}
      export TF_VAR_compartment_ocid=${var.compartment_id}
      export TF_VAR_language=${var.language}
      export TF_VAR_java_framework=${var.java_framework}
      export TF_VAR_java_vm=${var.java_vm}
      export TF_VAR_java_version=${var.java_version}
      export TF_VAR_vcn_strategy=${var.vcn_strategy}
      export TF_VAR_vcn_name=${var.vcn_name}
      export TF_VAR_vcn_ocid=${var.vcn_ocid}
      export TF_VAR_subnet_ocid=${var.subnet_ocid}
      export TF_VAR_ui_strategy=${var.ui_strategy}
      export TF_VAR_deploy_strategy=${var.deploy_strategy}
      export TF_VAR_kubernetes_strategy=${var.kubernetes_strategy}
      export TF_VAR_oke_strategy=${var.oke_strategy}
      export TF_VAR_oke_name=${var.oke_name}
      export TF_VAR_oke_ocid=${var.oke_ocid}
      export TF_VAR_db_strategy=${var.db_strategy}
      export TF_VAR_db_existing_strategy=${var.db_existing_strategy}
      export TF_VAR_atp_ocid=${var.atp_ocid}
      export TF_VAR_db_ocid=${var.db_ocid}
      export TF_VAR_mysql_ocid=${var.mysql_ocid}
      export TF_VAR_db_user=${var.db_user}
      # XXXXXX export TF_VAR_vault_secret_authtoken_ocid=XXXXXXX
      export TF_VAR_db_password=${var.db_password}
      export TF_VAR_vault_strategy=${var.vault_strategy}
      export TF_VAR_secret_strategy=${var.secret_strategy}
      export TF_VAR_vault_ocid=${var.vault_ocid}
      export TF_VAR_vault_secret_authtoken_ocid=${var.vault_secret_authtoken_ocid}
      ' > resource_manager_variables.sh
      chmod +x oci_starter.sh
      ./oci_starter.sh ${local.git_url} ${oci_devops_repository.test_repository.name} ${local.username}
    EOT
  }

  provisioner "local-exec" {
    command = "echo '(4) Finishing git clone command: '; ls -latr ${oci_devops_repository.test_repository.name}"
  }
}

locals {
  # OCI DevOps GIT login is tenancy/username
  username = var.oci_username != "" ? var.oci_username : local.current_user_name
  encode_user = urlencode("${data.oci_identity_tenancy.tenant_details.name}/${local.username}")
  encode_token  = urlencode(var.oci_token)
  git_url = "https://${local.encode_user}:${local.encode_token}@devops.scmservice.${var.region}.oci.oraclecloud.com/namespaces/${local.ocir_namespace}/projects/${oci_devops_project.test_project.name}/repositories/${oci_devops_repository.test_repository.name}"
}
