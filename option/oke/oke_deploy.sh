#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

export DOCKER_PREFIX=$TF_VAR_ocir
docker tag app:1.0 $DOCKER_PREFIX/app:1.0
docker push $DOCKER_PREFIX/app:1.0

docker tag ui:1.0 $DOCKER_PREFIX/ui:1.0
docker push $DOCKER_PREFIX/ui:1.0

sed "s/##DOCKER_PREFIX##/$DOCKER_PREFIX/" template.yaml > deploy.yaml

export KUBECONFIG=terraform/starter_cluster_kubeconfig
kubectl get node
kubectl create -f deploy.yaml