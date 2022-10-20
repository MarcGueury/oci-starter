#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

echo "OKE DESTROY"

if [ "$1" != "--auto-approve" ]; then
  read -p "Do you want to proceed? (yes/no) " yn

  case $yn in 
  	yes ) echo Deleting;;
	no ) echo Exiting...;
		exit;;
	* ) echo Invalid response;
		exit 1;;
  esac
fi

export KUBECONFIG=terraform/starter_kubeconfig

# Delete all ingress, services
kubectl delete ingress,services --all

# Delete the ingress controller
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.4.0/deploy/static/provider/cloud/deploy.yaml

