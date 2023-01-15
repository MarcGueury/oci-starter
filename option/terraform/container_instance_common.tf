# Check if the dynamic group exists before to create it
data "oci_identity_dynamic_groups" "starter_ci_dyngroup" {
    #Required
    compartment_id = var.tenancy_ocid
    name = "starter-ci-dyngroup"
    state = "ACTIVE"
}

resource "oci_identity_dynamic_group" "starter_ci_dyngroup" {
  count          = length(data.oci_identity_dynamic_groups.starter_ci_dyngroup.dynamic_groups)>0?0:1
  name           = "starter-ci-dyngroup"
  description    = "Starter - All Container Instances"
  compartment_id = var.tenancy_ocid
  matching_rule  = "ALL {resource.type='computecontainerinstance'}"
  freeform_tags = local.freeform_tags
}

# Check if the policy exists before to create it
data "oci_identity_policies" "starter-ci_policy" {
    #Required
    compartment_id = var.tenancy_ocid
    name = "starter-ci-policy"
    state = "ACTIVE"
}

resource "oci_identity_policy" "starter-ci_policy" {
  count          = length(data.oci_identity_policies.starter-ci_policy.policies)>0?0:1
  name           = "starter-ci-policy"
  description    = "Container instance access to OCIR"
  compartment_id = var.tenancy_ocid
  statements = [
    "allow dynamic-group starter-ci-dyngroup to read repos in tenancy"
  ]
  freeform_tags = local.freeform_tags
}
