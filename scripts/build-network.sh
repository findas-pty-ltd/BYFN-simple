#!/bin/bash


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $DIR/bash-settings.cfg
source $DIR/utils.sh # imports helper functions



function help(){
  echo 
  echo " ################################# "
  echo "      Configuring network           "
  echo " ################################# "
  echo 
  echo " ## High Detail Functions ## "
  echo "  "
  echo "  # > createChannel "
  echo "  # > joinChannel <peer> <org>"
  echo "  # > installChaincode <peer> <org> "
  echo "  # > instantiateChaincode <peer> <org> "
  echo
  echo 
  echo " ## Medium Detail Functions ## "
  echo "  # > init_channel "
  echo "  # > init_anchors "
  echo "  # > init_chaincode "
  echo 
  echo " ## Low Deatil Functions ## "
  echo "  # > start_network "
  echo
  echo 
  echo " To view what arguments to pars check the function header"
  echo " inside the ./byfn.sh file"
  echo 
}

##################################################
###                 Low-level (max detail)     ###
##################################################

# This function will join a peer to a channel 
# $1 : Int     -> the id of the peer
# $2 : Int     -> The id of the org
# $3 : ^String -> The channel name | default $CHANNEL_NAME
function joinChannel() {
  PEER=$1
  ORG=$2
  local channel=${3:-$CHANNEL_NAME}
  setGlobals $PEER $ORG

  set -x
  peer channel join -b $channel.block >&log.txt
  res=$?
  set +x
  cat log.txt
  if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
    COUNTER=$(expr $COUNTER + 1)
    echo "peer${PEER}.org${ORG} failed to join the channel, Retry after $DELAY seconds"
    sleep $DELAY
    joinChannel $PEER $ORG
  else
    COUNTER=1
  fi
  verifyResult $res "After $MAX_RETRY attempts, peer${PEER}.org${ORG} has failed to join channel '$channel' "
}

# This function will set a given peer to be an anchor for an Org
# $1 : Int     -> the id of the peer
# $2 : Int     -> The id of the org
# $3 : ^String -> The channel name | default $CHANNEL_NAME
function updateAnchorPeers() {
  PEER=$1
  ORG=$2
  channelname=${3:-$CHANNEL_NAME}
  setGlobals $PEER $ORG

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer channel update -o orderer.example.com:7050 -c $channelname -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
    res=$?
    set +x
  else
    set -x
    peer channel update -o orderer.example.com:7050 -c $channelname -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  echo "===================== Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$channelname' ===================== "
  sleep $DELAY
  echo
}

# This function will install chain code onto a peer
# $1 : Int     -> the id of the peer
# $2 : Int     -> The id of the org
# $3 : ^String -> The location of chaincode | default $CC_SRC_PATH
# $4 : Version -> The version that you want to set for the new install | default 1.0
# $5 : ^String  -> The Chaincode Name | default $CHAINCODE_NAME
function installChaincode() {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  
  local path=${3:-$CC_SRC_PATH}
  local version=${4:-1.0}
  local chaincode=${5:-$CHAINCODE_NAME}
  
  set -x
  peer chaincode install -n $chaincode -v $version -l $LANGUAGE -p $path >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode installation on peer${PEER}.org${ORG} has failed"
  echo "===================== Chaincode is installed on peer${PEER}.org${ORG} ===================== "
  echo
}

# This function will instantiate the chaincode. Chaincode can only be instantiated once on a network. 
# $1 : Int      -> the id of the peer
# $2 : Int      -> The id of the org
# $3 : ^String  -> The Channel Name | default $CHANNEL_NAME
# $4 : ^Version -> The version that you want to set for the new install | default 1.0
# $5 : ^String  -> The Chaincode Name | default $CHAINCODE_NAME
function instantiateChaincode() {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  
  local channel=${3:-$CHANNEL_NAME}
  local VERSION=${4:-1.0}
  local chaincode=${5:-$CHAINCODE_NAME}
  

  # while 'peer chaincode' command can get the orderer endpoint from the peer
  # (if join was successful), let's supply it directly as we know it using
  # the "-o" option
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer chaincode instantiate -o orderer.example.com:7050 -C $channel -n ${chaincode} -l ${LANGUAGE} -v ${VERSION} -c '{"Args":["init","a","100","b","200"]}' -P "AND ('Org1MSP.peer','Org2MSP.peer')" >&log.txt
    res=$?
    set +x
  else
    set -x
    peer chaincode instantiate -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $channel -n ${chaincode} -l ${LANGUAGE} -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "AND ('Org1MSP.member','Org2MSP.member')" >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Chaincode instantiation on peer${PEER}.org${ORG} on channel '$channel' failed"
  echo "===================== Chaincode is instantiated on peer${PEER}.org${ORG} on channel '$channel' ===================== "
  echo
}


# This function will query a value on the blockchain and will check the response
# $1 : Int     -> the id of the peer
# $2 : Int     -> The id of the org
# $3 : ^String -> Channel Name | default $CHANNEL_NAME
function createChannel() {
  echo "setting globals"
	PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  
  local channelname=${3:-$CHANNEL_NAME}

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
		peer channel create -o orderer.example.com:7050 -c $channelname -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
    set +x
	else
		set -x
		peer channel create -o orderer.example.com:7050 -c $channelname -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
		set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$channelname' created ===================== "
	echo
}



##################################################
###               Medium Detail                ###
##################################################

function init_channel(){
  echo "Creating channel..."
	createChannel 0 1
	echo "Join the peers to the channel..."
	joinChannel 0 1 # Joining peer 0 org 1
	joinChannel 1 1 # Joining peer 1 org 1
	joinChannel 0 2 # Joining peer 0 org 2
	joinChannel 1 2 # Joining peer 1 org 2
}

function init_anchors(){
	updateAnchorPeers 0 1 # Setting peer 0 org 1 as Anchor
	updateAnchorPeers 0 2 # Setting peer 0 org 2 as Anchor
}

function init_chaincode(){
  
	echo "Installing Chaincode ..."
	installChaincode 0 1 # Installing on peer 0 org 1
	installChaincode 1 1 # Installing on peer 1 org 1
	installChaincode 0 2 # Installing on peer 0 org 2
	installChaincode 1 2 # Installing on peer 1 org 2
	
	echo "Instantiate Chaincode ..."
	# The chain code can only be instantiaated once on the network
	instantiateChaincode 0 2 # Instantiating on peer 0 org 2
	
}


##################################################
###                  High-level (low detail)   ###
##################################################


# This function will configure all the running containers (peers, orderer, cli), and handle the chaincode.
# Step 1: Creates channel named "mychannel".
# Step 2: Connects all the peers to the channel
# Step 3: Sets up anchor peers, one anchor peer for each org in this setup.
# Step 4: Installs chaincode onto every peer. Note: chaincode only needs to be installed on peers that need to execute the chaincode.
# Step 5: Instantiates the chaincode on one peer only.
function start(){
  echo
  echo " ____    _____      _      ____    _____ "
  echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
  echo "\___ \    | |     / _ \   | |_) |   | |  "
  echo " ___) |   | |    / ___ \  |  _ <    | |  "
  echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
  echo
  echo "Build your first network (BYFN) end-to-end test"
  echo "Using the following settings"
  echo 
  
	## Create channel
	init_channel

  ## Set AnchorPeers
  init_anchors
  
  # Set up the chaincode
  init_chaincode
  
  echo
  echo "========= All GOOD, BYFN execution completed =========== "
  echo
  
  echo
  echo " _____   _   _   ____   "
  echo "| ____| | \ | | |  _ \  "
  echo "|  _|   |  \| | | | | | "
  echo "| |___  | |\  | | |_| | "
  echo "|_____| |_| \_| |____/  "
  echo
	
}






eval "$@"

exit 0