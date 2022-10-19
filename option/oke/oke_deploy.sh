#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

docker login ${TF_VAR_ocir} -u ${TF_VAR_namespace}/${TF_VAR_username} -p "${TF_VAR_token}"
export DOCKER_PREFIX=${TF_VAR_ocir}/${TF_VAR_namespace}
echo DOCKER_PREFIX=$DOCKER_PREFIX

docker tag app:1.0 $DOCKER_PREFIX/app:1.0
docker push $DOCKER_PREFIX/app:1.0

docker tag ui:1.0 $DOCKER_PREFIX/ui:1.0
docker push $DOCKER_PREFIX/ui:1.0

export KUBECONFIG=terraform/starter_cluster_kubeconfig

if[ ! -f deploy.yaml ]; then
  # Using & as separator
  sed "s&##DOCKER_PREFIX##&${DOCKER_PREFIX}&" oke/template.yaml > deploy.yaml
  helm install my-release nginx-stable/nginx-ingress
  kubectl create secret docker-registry ocirsecret --docker-server=$TF_VAR_ocir --docker-username="$TF_VAR_namespace/$TF_VAR_username" --docker-password="$TF_VAR_token" --docker-email="$TF_VAR_email"
  kubectl create secret generic db-secret --from-literal=db_user=$TF_VAR_db_user --from-literal=db_password=$TF_VAR_db_password --from-literal=jdbc_url=$TF_VAR_jdbc_url
fi

kubectl create -f deploy.yaml