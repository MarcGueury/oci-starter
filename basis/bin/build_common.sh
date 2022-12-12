# Build_common.sh

# SCRIPT_DIR should be set by the calling scripts 
cd $SCRIPT_DIR
if [ -z "$TF_VAR_deploy_strategy" ]; then
  . ../../env.sh
else 
  . ../../bin/common.sh
fi 

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
   if [ ! -d ../../target/compute ]; then
      mkdir ../../target/compute
      cp ../compute/* ../../target/compute/.
   fi
fi