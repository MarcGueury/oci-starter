variable "cluster_kube_config_expiration" {
  default = 2592000
}

variable "cluster_kube_config_token_version" {
  default = "2.0.0"
}

data "oci_containerengine_cluster_kube_config" "starter_cluster_kube_config" {
  #Required
  cluster_id = local.oke_ocid

  #Optional
  expiration    = var.cluster_kube_config_expiration
  token_version = var.cluster_kube_config_token_version
}

resource "local_file" "starter_cluster_kube_config_file" {
  content  = data.oci_containerengine_cluster_kube_config.starter_cluster_kube_config.content
  filename = "${path.module}/starter_kubeconfig"
}

