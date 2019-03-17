#!/bin/bash


#export PATH=${PWD}/bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export VERBOSE=false


# sources the default configs
source ./scripts/bash-settings.cfg

## Cleans all the generated files
function clean(){
  rm -rf ./channel-artifacts
  rm -rf ./crypto-config
}

## High Detail

##################################################
###               Cert Generation              ###
##################################################

# This function will create the certifications for the different orgs from the crypto-config.yaml
# This function automaticly creates the crypto-config folder
# $1: ^String -> The crypto-config.yaml location | default ./crypto-config.yaml 
function create_certs(){
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi
  echo
  echo "##########################################################"
  echo "##### Generate certificates using cryptogen tool #########"
  echo "##########################################################"

  if [ -d "crypto-config" ]; then
    rm -Rf crypto-config
  fi
  set -x
  cryptogen generate --config=${1:-./crypto-config.yaml}
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi
  echo
}


CA1_PRIVATE_KEY=""
CA2_PRIVATE_KEY=""
# This function takes the generated certs and adds the key to the given CA's yaml file
function inject_keys(){
  # sed on MacOSX does not support -i flag with a null extension. We will use
  # 't' for our back-up's extension and delete it at the end of the function
  ARCH=$(uname -s | grep Darwin)
  if [ "$ARCH" == "Darwin" ]; then
    OPTS="-it"
  else
    OPTS="-i"
  fi

  # Copy the template to the file that will be modified to add the private key
  # cp docker-compose.orginal.yaml docker-compose.yaml

  # The next steps will replace the template's contents with the
  # actual values of the private key file names for the two CAs.
  CURRENT_DIR=$PWD
  cd crypto-config/peerOrganizations/org1.example.com/ca/
  CA1_PRIVATE_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"
  #sed $OPTS "s/CA1_PRIVATE_KEY/${CA1_PRIVATE_KEY}/g" docker-compose.yaml
  cd crypto-config/peerOrganizations/org2.example.com/ca/
  CA2_PRIVATE_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"
  #sed $OPTS "s/CA2_PRIVATE_KEY/${CA2_PRIVATE_KEY}/g" docker-compose.yaml
  # If MacOSX, remove the temporary backup of the docker-compose file
  if [ "$ARCH" == "Darwin" ]; then
    rm docker-compose.yamlt
  fi
}


# original
function generateCerts() {
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi
  echo
  echo "##########################################################"
  echo "##### Generate certificates using cryptogen tool #########"
  echo "##########################################################"

  if [ -d "crypto-config" ]; then
    rm -Rf crypto-config
  fi
  set -x
  cryptogen generate --config=./crypto-config.yaml
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi
  echo
}



##################################################
###             Artifact Generation            ###
##################################################

# This function will create a channel artifact
# $1: ^String -> Channel Name | default $CHANNEL_NAME
# $2: ^String -> Output file of the channel file  | default $ARTIFACT_DEFAULT/channel.tx
# $3: ^String -> profile to use for the genesis generation pulled from the configtx.yaml | default TwoOrgsChannel  
function create_channel_artifact(){
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi
  mkdir -p $(dirname ${2:-$ARTIFACT_DEFAULT/channel.tx})
  echo
  echo "#################################################################"
  echo "### Generating channel configuration transaction 'channel.tx' ###"
  echo "#################################################################"
  set -x
  configtxgen -profile ${3:-TwoOrgsChannel} -outputCreateChannelTx ${2:-$ARTIFACT_DEFAULT/channel.tx} -channelID ${1:-$CHANNEL_NAME}
  
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi
}

# This function will create a genesis block artifact
# $1: ^String -> Output folder of the genesis.block | default $ARTIFACT_DEFAULT
# $2: ^String -> Channel Name | default $CHANNEL_NAME
# $3: ^String -> profile to use for the genesis generation pulled from the configtx.yaml | default TwoOrgsOrdererGenesis
function create_genesisblock_artifact(){
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi
  mkdir -p ${1:-$ARTIFACT_DEFAULT}
  echo "##########################################################"
  echo "#########  Generating Orderer Genesis block ##############"
  echo "##########################################################"
  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  set -x
                                                              # channel id can not be the same as the orgs 
  configtxgen -profile ${3:-TwoOrgsOrdererGenesis} -channelID byfn-sys-channel  -outputBlock ${1:-$ARTIFACT_DEFAULT}/genesis.block
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi
}

# This function will create an organisation artifact
# $1: String  -> Organisation MSP name  | example Org1MSP
# $2: ^String -> Output folder of the genesis.block | default $ARTIFACT_DEFAULT
# $3: ^String -> Channel Name | default $CHANNEL_NAME
# $4: ^String -> The profile to use from the configtx.yaml | default TwoOrgsChannel
function create_organisation_artifact(){
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi
  mkdir -p ${2:-$ARTIFACT_DEFAULT}
  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for ${1}   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile ${4:-TwoOrgsChannel} -outputAnchorPeersUpdate \
    ${2:-$ARTIFACT_DEFAULT}/${1}anchors.tx -channelID ${3:-$CHANNEL_NAME}  -asOrg ${1}
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for ${1}..."
    exit 1
  fi
}

# original 
function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi
  
  mkdir -p $ARTIFACT_DEFAULT
  
  if [ ${1:-1} -eq 1 ] ; then 
    echo "##########################################################"
    echo "#########  Generating Orderer Genesis block ##############"
    echo "##########################################################"
    # Note: For some unknown reason (at least for now) the block file can't be
    # named orderer.genesis.block or the orderer will fail to launch!
    set -x
    configtxgen -profile TwoOrgsOrdererGenesis -channelID byfn-sys-channel -outputBlock ./channel-artifacts/genesis.block
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate orderer genesis block..."
      exit 1
    fi
  else
    create_genesisblock_artifact $ARTIFACT_DEFAULT $CHANNEL_NAME TwoOrgsOrdererGenesis
  fi  
  
  if [ ${2:-1} -eq 1 ] ; then 
    echo
    echo "#################################################################"
    echo "### Generating channel configuration transaction 'channel.tx' ###"
    echo "#################################################################"
    set -x
    configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate channel configuration transaction..."
      exit 1
    fi
  else
    create_channel_artifact $CHANNEL_NAME $ARTIFACT_DEFAULT/channel.tx TwoOrgsChannel
  fi
  
  if [ ${3:-1} -eq 1 ] ; then 
    echo
    echo "#################################################################"
    echo "#######    Generating anchor peer update for Org1MSP   ##########"
    echo "#################################################################"
    set -x
    configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate anchor peer update for Org1MSP..."
      exit 1
    fi
  else
    create_organisation_artifact Org1MSP $ARTIFACT_DEFAULT $CHANNEL_NAME TwoOrgsChannel
  fi
  
  if [ ${4:-1} -eq 1 ] ; then 
    echo
    echo "#################################################################"
    echo "#######    Generating anchor peer update for Org2MSP   ##########"
    echo "#################################################################"
    set -x
    configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate \
      ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate anchor peer update for Org2MSP..."
      exit 1
    fi
  else
    create_organisation_artifact Org2MSP $ARTIFACT_DEFAULT $CHANNEL_NAME TwoOrgsChannel
  fi
  echo
}




## Medium Detail

function generate_certs(){
    create_certs
    inject_keys
}

function generate_artifacts(){
    create_channel_artifact $CHANNEL_NAME $ARTIFACT_DEFAULT/channel.tx TwoOrgsChannel
    create_genesisblock_artifact $ARTIFACT_DEFAULT $CHANNEL_NAME TwoOrgsOrdererGenesis
    create_organisation_artifact Org1MSP $ARTIFACT_DEFAULT $CHANNEL_NAME TwoOrgsChannel
    create_organisation_artifact Org2MSP $ARTIFACT_DEFAULT $CHANNEL_NAME TwoOrgsChannel
}

function boot_containers(){
    echo boot_containers
    IMAGE_TAG=$IMAGETAG \
    COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME \
    CA1_PRIVATE_KEY=$CA1_PRIVATE_KEY \
    CA2_PRIVATE_KEY=$CA2_PRIVATE_KEY \
    docker-compose -f $COMPOSE_FILE up -d 2>&1
}

function run_inner_script(){
  docker exec cli scripts/script.sh start_network $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT $VERBOSE 2>&1
}



## Low Detail

function up(){
    generate_certs
    generate_artifacts
    boot_containers
    run_inner_script
}
function up_test(){
    #generate_certs
    generateCerts
    #generate_artifacts
    generateChannelArtifacts 0 0 0 0
    boot_containers
    run_inner_script
}

function down(){
    echo down
    # stop org3 containers also in addition to org1 and org2, in case we were running sample to add org3
    echo docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_ORG3 down --volumes --remove-orphans
    IMAGE_TAG=$IMAGETAG \
    COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME \
    CA1_PRIVATE_KEY=$CA1_PRIVATE_KEY \
    CA2_PRIVATE_KEY=$CA2_PRIVATE_KEY \
    docker-compose -f $COMPOSE_FILE down --volumes --remove-orphans
    # Bring down the network, deleting the volumes
    #Delete any ledger backups
    docker run -v $PWD:/tmp/first-network --rm hyperledger/fabric-tools:$IMAGETAG rm -Rf /tmp/first-network/ledgers-backup
    #Cleanup the chaincode containers
    CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*.mycc.*/) {print $1}')
    if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
      echo "---- No containers available for deletion ----"
    else
      docker rm -f $CONTAINER_IDS
    fi
    #Cleanup images
    DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*.mycc.*/) {print $3}')
    if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
      echo "---- No images available for deletion ----"
    else
      docker rmi -f $DOCKER_IMAGE_IDS
    fi
    # Removes all files
    clean
    
}

function help(){
  echo 
  echo " ################################# "
  echo "             BYFN Simple           "
  echo " ################################# "
  echo 
  echo " ## High Detail Functions ## "
  echo "  ## Cert Generation # "
  echo "  # > create_certs "
  echo "  # > inject_keys "
  echo "  #"
  echo "  ## Artifact Generation # "
  echo "  # > create_channel_artifact "
  echo "  # > create_genesisblock_artifact "
  echo "  # > create_organisation_artifact "
  echo 
  echo " ## Medium Detail Functions ## "
  echo "  # > generate_certs "
  echo "  # > generate_artifacts "
  echo "  # > boot_containers "
  echo "  # > run_inner_script "
  echo 
  echo " ## Low Deatil Functions ## "
  echo "  # > up "
  echo "  # > down "
  echo 
  echo " To view what arguments to pars check the function header"
  echo " inside the ./byfn.sh file"
  echo 
}

eval "$@"

exit


