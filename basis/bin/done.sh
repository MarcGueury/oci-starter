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
elif [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
  export KUBECONFIG=$SCRIPT_DIR/../terraform/starter_kubeconfig
  export UI_URL=http://`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
fi

echo 
echo "Build done"
if [ ! -z "$UI_URL" ]; then
  wget $UI_URL          -o /tmp/wget.log -O /tmp/result.html
  wget $UI_URL/app/dept -o /tmp/wget.log -O /tmp/result.json
  wget $UI_URL/app/info -o /tmp/wget.log -O /tmp/result.info
  echo - User Interface : $UI_URL
  echo - Rest DB API    : $UI_URL/app/dept
  echo - Rest Info API  : $UI_URL/app/info
fi


