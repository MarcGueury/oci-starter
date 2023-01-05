# Groups names
locals {
#  jms_group="${var.prefix}-fleet-managers"
  jms_group="FLEET_MANAGERS"
  jms_dyngroup="${var.prefix}-jms-dyngroup"
}

/*
# User Group
resource "oci_identity_group" "starter_jms_group" {
  name           = local.jms_group
  description    = local.jms_group
  compartment_id = var.tenancy_ocid
  freeform_tags = local.freeform_tags
}

resource "oci_identity_user_group_membership" "starter_jms_group_memb" {
  compartment_id = var.tenancy_ocid
  user_id        = var.user_ocid
  group_id       = oci_identity_group.starter_jms_group.id
}
*/

# Dynamic Group
resource "oci_identity_dynamic_group" "starter_jms_dyngroup" {
  compartment_id = var.tenancy_ocid
  name           = local.jms_dyngroup
  description    = local.jms_dyngroup
  matching_rule  = "ANY { ANY {instance.compartment.id = '${var.compartment_ocid}'}, ALL {resource.type='managementagent', resource.compartment.id='${var.compartment_ocid}'} }"
  freeform_tags = local.freeform_tags
}

# Policies
resource "oci_identity_policy" "starter_jms_policy" {
  compartment_id = var.tenancy_ocid
  description    = "${var.prefix}-jms-${data.oci_identity_compartment.compartment.name}"
  name           = "${var.prefix}-jms-${data.oci_identity_compartment.compartment.name}"
  statements     = [
/*
    "ALLOW GROUP ${local.jms_group} TO MANAGE fleet IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW GROUP ${local.jms_group} TO MANAGE management-agents IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW GROUP ${local.jms_group} TO READ METRICS IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW GROUP ${local.jms_group} TO MANAGE tag-namespaces IN TENANCY",
    "ALLOW GROUP ${local.jms_group} TO MANAGE instance-family IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW GROUP ${local.jms_group} TO READ instance-agent-plugins IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW GROUP ${local.jms_group} TO MANAGE management-agent-install-keys IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW GROUP ${local.jms_group} TO MANAGE log-groups IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW GROUP ${local.jms_group} TO MANAGE log-content IN COMPARTMENT ID ${var.compartment_ocid}",
*/
    "ALLOW SERVICE javamanagementservice TO USE management-agent-install-keys IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW SERVICE javamanagementservice TO MANAGE metrics IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.metrics.namespace='java_management_service'", 
    "ALLOW SERVICE javamanagementservice TO MANAGE log-groups IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW SERVICE javamanagementservice TO MANAGE log-content IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW SERVICE javamanagementservice TO READ instances IN tenancy",
    "ALLOW SERVICE javamanagementservice TO INSPECT instance-agent-plugins IN tenancy",

    "ALLOW DYNAMIC-GROUP ${local.jms_dyngroup} TO USE METRICS IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW DYNAMIC-GROUP ${local.jms_dyngroup}  TO MANAGE management-agents IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW DYNAMIC-GROUP ${local.jms_dyngroup}  TO USE tag-namespaces IN TENANCY", 
    "ALLOW DYNAMIC-GROUP ${local.jms_dyngroup}  TO MANAGE log-content IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW dynamic-group ${local.jms_dyngroup} TO MANAGE instances IN COMPARTMENT ID ${var.compartment_ocid}"
  ]
  freeform_tags = local.freeform_tags
}

resource "oci_logging_log" "starter_jms_inventory_log" {
  display_name = "${var.prefix}-jms-inventory-log"
  log_group_id = oci_logging_log_group.starter_log_group.id
  log_type     = "CUSTOM"
  freeform_tags = local.freeform_tags
}

resource "oci_logging_log" "starter_jms_operation_log" {
  display_name = "${var.prefix}-jms-operation-log"
  log_group_id = oci_logging_log_group.starter_log_group.id
  log_type     = "CUSTOM"
  freeform_tags = local.freeform_tags
}

# JMS Fleet
resource oci_jms_fleet starter_fleet {
  compartment_id = var.compartment_ocid
  display_name   = "${var.prefix}-jms-fleet"
  description = "${var.prefix}-jms-fleet"
  is_advanced_features_enabled = true
  inventory_log {
     log_group_id = oci_logging_log_group.starter_log_group.id
     log_id = oci_logging_log.starter_jms_inventory_log.id
  }
  operation_log {
    log_group_id = oci_logging_log_group.starter_log_group.id
    log_id       = oci_logging_log.starter_jms_operation_log.id
  }
  freeform_tags = local.freeform_tags
}

# Object storage bucket with the name=ocid of the Fleet
resource "oci_objectstorage_bucket" "starter_jms_bucket" {
  compartment_id = var.compartment_ocid
  namespace      = var.namespace
  name           = "${oci_jms_fleet.starter_fleet.id}"
  freeform_tags = local.freeform_tags
}

# Installation Key
resource "oci_management_agent_management_agent_install_key" "starter_install_key" {
    #Required
    compartment_id = var.compartment_ocid
    display_name   = "${var.prefix}-install-key"
    #Optional
    is_unlimited = true
}

output fleet_ocid {
  value=oci_jms_fleet.starter_fleet.id
}

output install_key_ocid {
  value=oci_management_agent_management_agent_install_key.starter_install_key.id
}

/*
oci management-agent install-key list --compartment-id $TF_VAR_compartment_ocid


    export compartment_id=<substitute-value-of-compartment_id> # https://docs.cloud.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/jms/fleet/create.html#cmdoption-compartment-id
    export display_name=<substitute-value-of-display_name> # https://docs.cloud.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/jms/fleet/create.html#cmdoption-display-name
    export install_key_id=ocid1.managementagentinstallkey.oc1.xxxxxxxx
    
    
    <substitute-value-of-install_key_id> # https://docs.cloud.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/jms/fleet/generate-agent-deploy-script.html#cmdoption-install-key-id
    export is_user_name_enabled=<substitute-value-of-is_user_name_enabled> # https://docs.cloud.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/cmdref/jms/fleet/generate-agent-deploy-script.html#cmdoption-is-user-name-enabled
    export os_family="LINUX"

    fleet_id=$(oci jms fleet create --compartment-id $compartment_id --display-name $display_name --inventory-log file://inventory-log.json --query data.id --raw-output)

cd data/github/mgueury.skynet.be/testsuite/test_group_all/group_common
. ./env.sh
oci management-agent install-key list --compartment-id $TF_VAR_compartment_ocid
oci jms fleet list --compartment-id $TF_VAR_compartment_ocid
INSTALL_KEY_OCID=ocid1.managementagentinstallkey.oc1.xxx
FLEET_OCID=ocid1.jmsfleet.oc1.xxx
oci jms fleet generate-agent-deploy-script --file /tmp/install_jms.sh --fleet-id $FLEET_OCID --install-key-id $INSTALL_KEY_OCID --is-user-name-enabled true --os-family "LINUX"
*/