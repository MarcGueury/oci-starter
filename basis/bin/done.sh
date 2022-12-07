#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..

if [ -z "$TF_VAR_deploy_strategy" ]; then
  . ./env.sh -silent
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
  export UI_URL=http://`kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`/${TF_VAR_prefix}
elif [ "$TF_VAR_deploy_strategy" == "function" ]; then  
  export UI_URL=https://${APIGW_HOSTNAME}/${TF_VAR_prefix}
fi

echo 
echo "Build done"
if [ ! -z "$UI_URL" ]; then
  # Check the URL if running in the test_suite
  if [ ! -z "$TEST_NAME" ]; then
    if [ "$TF_VAR_deploy_strategy" == "kubernetes" ]; then
      kubectl wait --for=condition=ready pod ${TF_VAR_prefix}-app
      kubectl wait --for=condition=ready pod ${TF_VAR_prefix}-ui
      kubectl get all
      sleep 5
    fi
    # Needed for ORDS or Go that takes more time to start
    curl $UI_URL/         --retry 5 --retry-max-time 20 -D /tmp/result_html.log > /tmp/result.html
    curl $UI_URL/app/dept --retry 5 --retry-max-time 20 -D /tmp/result_json.log > /tmp/result.json
    curl $UI_URL/app/info --retry 5 --retry-max-time 20 -D /tmp/result_info.log > /tmp/result.info
  fi
  echo - User Interface : $UI_URL/
  echo - Rest DB API    : $UI_URL/app/dept
  echo - Rest Info API  : $UI_URL/app/info
fi


