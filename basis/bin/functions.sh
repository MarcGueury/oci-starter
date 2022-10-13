#!/bin/bash
fn list context
fn use context eu-frankfurt-1
fn update context $TF_VAR_compartment_ocid
fn update context registry ${TF_VAR_registry_path}
echo ${OCI_TOKEN} | docker login ${TF_VAR_ocir_docker_repository} -u ${DOCKER_USER} --password-stdin
fn list apps
# Build the FN docker image
fn build
# Push it to registry
fn push
