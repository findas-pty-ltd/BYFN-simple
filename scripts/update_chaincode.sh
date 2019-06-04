#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/bash-settings.cfg
source $DIR/utils.sh # imports helper functions



function update(){
    
    version=$1
    echo " Updating chaincode to version $version "
    installChaincode 0 1 $version mycc
    upgradeChaincode 0 1 $version

}

function installChaincode() {
  PEER=$1
  ORG=$2

  setGlobals $PEER $ORG
  
  local version=${3:-1.0}
  local chaincode=${4:-$CHAINCODE_NAME}
  local path=${5:-$CC_SRC_PATH}
  
  set -x
  peer chaincode install -n $chaincode -v $version -l $LANGUAGE -p $path >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode installation on peer${PEER}.org${ORG} has failed"
  echo "===================== Chaincode is installed on peer${PEER}.org${ORG} ===================== "
  echo
}

update $1


#eval "$@"

exit 0