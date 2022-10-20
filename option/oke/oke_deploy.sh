#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

docker login ${TF_VAR_ocir} -u ${TF_VAR_namespace}/${TF_VAR_username} -p "${TF_VAR_auth_token}"
echo DOCKER_PREFIX=$DOCKER_PREFIX

docker tag app:1.0 $DOCKER_PREFIX/app:1.0
docker push $DOCKER_PREFIX/app:1.0

docker tag ui:1.0 $DOCKER_PREFIX/ui:1.0
docker push $DOCKER_PREFIX/ui:1.0

export KUBECONFIG=terraform/starter_cluster_kubeconfig
chmod 600 $KUBECONFIG

if [ ! -f deploy.yaml ]; then
  # Using & as separator
  sed "s&##DOCKER_PREFIX##&${DOCKER_PREFIX}&" oke/template.yaml > deploy.yaml
  
  kubectl create clusterrolebinding jdoe_clst_adm --clusterrole=cluster-admin --user=$TF_VAR_user_ocid
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.4.0/deploy/static/provider/cloud/deploy.yaml
  kubectl get svc -n ingress-nginx

  kubectl create secret docker-registry ocirsecret --docker-server=$TF_VAR_ocir --docker-username="$TF_VAR_namespace/$TF_VAR_username" --docker-password="$TF_VAR_auth_token" --docker-email="$TF_VAR_email"
  kubectl create secret generic db-secret --from-literal=db_user=$TF_VAR_db_user --from-literal=db_password=$TF_VAR_db_password --from-literal=jdbc_url=$JDBC_URL
fi

kubectl create -f deploy.yaml
echo INGRESS_IP=`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
