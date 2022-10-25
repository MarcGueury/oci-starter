#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

if [ -z "TF_VAR_deploy_strategy" ]; then
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
if [ -v UI_URL ]; then
  # Check the URL if running in the test_suite
  if [ -v TEST_NAME ]; then
    if [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
      kubectl wait --for=condition=ready pod app
      kubectl wait --for=condition=ready pod ui
      kubectl get all
      sleep 5
    fi
    wget $UI_URL          -o /tmp/result_html.log -O /tmp/result.html
    wget $UI_URL/app/dept -o /tmp/result_json.log -O /tmp/result.json
    wget $UI_URL/app/info -o /tmp/result_info.log -O /tmp/result.info
  fi
  echo - User Interface : $UI_URL
  echo - Rest DB API    : $UI_URL/app/dept
  echo - Rest Info API  : $UI_URL/app/info
fi


