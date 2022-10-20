#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

if [ -z "TF_VAR_deploy_stategy" ]; then
  . ./variables.sh
fi 

get_output_from_tfstate () {
  RESULT=`jq -r '.outputs."'$2'".value' terraform/terraform.tfstate`
  echo "$1=$RESULT"
  export $1=$RESULT
}

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
  get_output_from_tfstate UI_URL ui_url  
  get_output_from_tfstate REST_URL rest_url  
elif [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
  export KUBECONFIG=$SCRIPT_DIR/../terraform/starter_kubeconfig
  export UI_URL=http://`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
  export REST_URL=$UI_URL/app/dept
fi

echo 
echo "Build done"
if [ ! -z "$UI_URL" ]; then
  wget $UI_URL   -o /tmp/result.html
  wget $REST_URL -o /tmp/result.json
  echo - User Interface : $UI_URL
  echo - Rest API : $REST_URL
fi


