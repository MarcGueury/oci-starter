# Build_common.sh
BIN_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# SCRIPT_DIR should be set by the calling scripts 
cd $SCRIPT_DIR
if [ -z "$TF_VAR_deploy_strategy" ]; then
  . $BIN_DIR/../env.sh
else 
  . $BIN_DIR/common.sh
fi 

if [ "$TF_VAR_deploy_strategy" == "compute" ]; then
   if [ ! -d $ROOT_DIR/target/compute ]; then
      mkdir $ROOT_DIR/target/compute
      cp $ROOT_DIR/src/compute/* $ROOT_DIR/target/compute/.
   fi
fi