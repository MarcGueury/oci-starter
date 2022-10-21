#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

if [ -z $DOCKER_PREFIX ]; then
  echo "Set up the variables before to run this script by running:"
  echo ". bin/env_pre_terraform.sh"
  echo ". bin/env_post_terraform.sh"
  exit
fi

# Docker Login
docker login ${TF_VAR_ocir} -u ${TF_VAR_namespace}/${TF_VAR_username} -p "${TF_VAR_auth_token}"
echo DOCKER_PREFIX=$DOCKER_PREFIX

# Push image in registry
docker tag app $DOCKER_PREFIX/app
docker push $DOCKER_PREFIX/app

docker tag ui $DOCKER_PREFIX/ui
docker push $DOCKER_PREFIX/ui

# Configure KUBECTL
export KUBECONFIG=terraform/starter_kubeconfig

# One time configuration
if [ ! -f oke/app.yaml ]; then
  chmod 600 $KUBECONFIG
 
  # Deploy ingress-nginx
  kubectl create clusterrolebinding jdoe_clst_adm --clusterrole=cluster-admin --user=$TF_VAR_user_ocid
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.4.0/deploy/static/provider/cloud/deploy.yaml
  kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
  kubectl wait --namespace ingress-nginx --for=condition=Complete job/ingress-nginx-admission-patch  
  # Wait for the ingress external IP
  external_ip=""
  while [ -z $external_ip ]; do
    echo "Waiting for external IP..."
    external_ip=$(kubectl get svc -n ingress-nginx ingress-nginx-controller --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
    if [ -z "$external_ip" ]; then
      sleep 10
    fi
  done

  date
  kubectl get all -n ingress-nginx
  sleep 5
  echo "Ingress ready: $external_ip"

  # Create secrets
  kubectl create secret docker-registry ocirsecret --docker-server=$TF_VAR_ocir --docker-username="$TF_VAR_namespace/$TF_VAR_username" --docker-password="$TF_VAR_auth_token" --docker-email="$TF_VAR_email"
  # XXXX - Tthis should be by date 
  kubectl create secret generic db-secret --from-literal=db_user=$TF_VAR_db_user --from-literal=db_password=$TF_VAR_db_password --from-literal=jdbc_url=$JDBC_URL --from-literal=spring_application_json='{ "db.url": "'$JDBC_URL'" }'
fi

# Using & as separator
sed "s&##DOCKER_PREFIX##&${DOCKER_PREFIX}&" app_src/app.yaml > oke/app.yaml
sed "s&##DOCKER_PREFIX##&${DOCKER_PREFIX}&" ui_src/ui.yaml > oke/ui.yaml

# Create objects in Kubernetes
kubectl apply -f oke/app.yaml
kubectl apply -f oke/ui.yaml
kubectl apply -f oke/ingress.yaml

