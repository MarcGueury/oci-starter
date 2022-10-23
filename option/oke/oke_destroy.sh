#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

echo "OKE DESTROY"

if [ "$1" != "--auto-approve" ]; then
  echo "Error: Please call this script via destroy.sh"
  exit
fi

export KUBECONFIG=terraform/starter_kubeconfig

# The goal is to destroy all LoadBalancers created by OKE in OCI before to delete OKE.
#
# Delete all ingress, services
kubectl delete ingress,services --all

# Delete the ingress controller
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.4.0/deploy/static/provider/cloud/deploy.yaml

