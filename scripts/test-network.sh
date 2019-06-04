#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/bash-settings.cfg
source $DIR/utils.sh # imports helper functions


function help() {
  echo ""
  echo " ################################# "
  echo "      Test network           "
  echo " ################################# "
  echo ""
  echo " > chaincodeQuery [peer int] [org int]"
  echo " > chaincodeInvoke [peer int] [org int]"
  echo " > chaincodeInvoke [peer int] [org int]"
  echo ""
  echo " To view what arguments to pars check the function header"
  echo " inside the ./scripts/test-network.sh file"
}
    
# This function will query a value on the blockchain and will check the response
# $1 : Int     -> the id of the peer
# $2 : Int     -> The id of the org
# $3 : Any     -> The expected response
# $4 : ^String -> Channel Name | default $CHANNEL_NAME
# $5 : ^String -> Chaincode Name | defualt $CHAINCODE_NAME
function chaincodeQuery() {
    
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  local expected_result=$3
  local channelname=${4:-$CHANNEL_NAME}
  local mycc=${5:-$CHAINCODE_NAME}
  local rc=1
  local starttime=$(date +%s)
  
  
  echo "===================== Querying on peer${PEER}.org${ORG} on channel '$channelname'... ===================== "


  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while
    test "$(($(date +%s) - starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
    sleep $DELAY
    echo "Attempting to Query peer${PEER}.org${ORG} ...$(($(date +%s) - starttime)) secs"
    set -x
    peer chaincode query -C $channelname -n $mycc -c '{"function":"Read", "Args":["Business","1"]}' >&log.txt
    res=$?
    set +x
    test $res -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
    test "$VALUE" = "$expected_result" && let rc=0
    # removed the string "Query Result" from peer chaincode query command
    # result. as a result, have to support both options until the change
    # is merged.
    test $rc -ne 0 && VALUE=$(cat log.txt | egrep '^[0-9]+$')
    test "$VALUE" = "$expected_result" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query successful on peer${PEER}.org${ORG} on channel '$channelname' ===================== "
  else
    echo "!!!!!!!!!!!!!!! Query result on peer${PEER}.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
    echo
    exit 1
  fi
}


# This function will obtain a connection with selected peers and execute the chaincode
# $1 : String -> Channelname
# $2 : String -> Chaincode name
# $3 : Int    -> id of first validating peer
# $4 : Int    -> id of first validating org
# $5>: Int    -> id of next validating peer | you can continue to enter peer org combinations 
# $6>: Int    -> id of next validating org  | you can continue to enter peer org combinations
function chaincodeInvoke() {
  channel=$1
  chaincode=$2
  shift 2
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$channel' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer chaincode invoke -o orderer.example.com:7050 -C $channel -n $chaincode $PEER_CONN_PARMS -c '{"Args":["invoke","a","b","10"]}' >&log.txt
    res=$?
    set +x
  else
    set -x
    peer chaincode invoke -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $channel -n $chaincode $PEER_CONN_PARMS -c '{"Args":["invoke","a","b","10"]}' >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$channel' ===================== "
  echo
}

# This function is a quick way to run query functions on the network
# Example > ./test-network.sh query 0 1 query a
# This will return the value for item 'a'
# $1 : Int    -> The id of the peer
# $2 : Int    -> The id of the org
# $3 : String -> Name of the query function you want to run
# $@ : Any    -> Any arguments required for to run the query
function query() {  
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  func=$3
  shift 3
  args=$@
  echo $args
  command='{"Args":["'$func'"'
  for arg in $args 
  do
    command=$command',"'$arg'"'
  done
  command=$command']}'
  echo "Built Command -> $command"
  

  local rc=1
  local starttime=$(date +%s)
  
  
  echo "===================== Querying on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME'... ===================== "


  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while
    test "$(($(date +%s) - starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
    sleep $DELAY
    echo "Attempting to Query peer${PEER}.org${ORG} ...$(($(date +%s) - starttime)) secs"
    set -x
    peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME -c $command >&log.txt
    res=$?
    set +x
    test $res -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
    test "$VALUE" = "$expected_result" && let rc=0
    # removed the string "Query Result" from peer chaincode query command
    # result. as a result, have to support both options until the change
    # is merged.
    test $rc -ne 0 && VALUE=$(cat log.txt | egrep '^[0-9]+$')
    test "$VALUE" = "$expected_result" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query successful on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' ===================== "
  else
    echo "!!!!!!!!!!!!!!! Query result on peer${PEER}.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
    echo
    exit 1
  fi
}

# This function is a quick way to run invoke functions on the network
# Example > ./test-network.sh invoke invoke a b 10
# This will trasfer 10 from a to b
# $1 : String -> Name of the invoke function you want to run
# $@ : Any    -> Any arguments required for to run the query
function invoke() {
  func=$1
  shift 1
  args=$@
  
  echo "===================== Invoke transaction started on $PEERS on channel '$CHANNEL_NAME' ===================== "

  parsePeerConnectionParameters 0 1
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  command='{"Args":["'$func'"'
  for arg in $args 
  do
    command=$command',"'$arg'"'
  done
  command=$command']}'
  echo "Built Command -> $command"


  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n $CHAINCODE_NAME $PEER_CONN_PARMS -c $command >&log.txt
    res=$?
    set +x
  else
    set -x
    peer chaincode invoke -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME $PEER_CONN_PARMS -c $command >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
  echo
}


# This function runs a query on the blockchain 
function test_chaincode(){
    
    chaincodeQuery 0 1
    chaincodeInvoke $CHANNEL_NAME $CHAINCODE_NAME 0 1 0 2
    chaincodeQuery 1 2
    
}

eval "$@"

exit 0