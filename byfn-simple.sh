#!/bin/bash


export PATH=${PWD}/bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}



# sources the default configs
source ./scripts/bash-settings.cfg

## Cleans all the generated files
function clean(){
  rm -rf ./channel-artifacts
  rm -rf ./crypto-config
}

## Prints the help menu
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
  echo " inside the ./byfn-simple.sh file"
  echo 
}


## This function will pull the required docker containers
function pullContainers() {
    IMAGE_TAG=$IMAGETAG \
    COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME \
    CA1_PRIVATE_KEY=$CA1_PRIVATE_KEY \
    CA2_PRIVATE_KEY=$CA2_PRIVATE_KEY \
    ARTIFACT_DEFAULT=$ARTIFACT_DEFAULT \
    docker-compose -f $COMPOSE_FILE pull 2>&1
}

## This function will make sure that you are using the same version for the docker images and binnaries
function checkPrereqs() {
  # Note, we check configtxlator externally because it does not require a config file, and peer in the
  # docker image because of FAB-8551 that makes configtxlator return 'development version' in docker
  passing=1
  if [ -n "$(which node)" ] ; then
      NODE_VERSION=$(node -v |sed -ne 's/v//p' | sed 's/\./  /g' | awk '{print $1}')
      echo "node is installed version:$GIT_VERSION"
    else
      echo "node is not installed or the Path is not set"
      passing=0
  fi
  if [ -n "$(which git)" ] ; then
      GIT_VERSION=$(git --version | sed -ne 's/git version //p')
      echo "git is installed version:$GIT_VERSION"
    else
      echo "git is not installed or the Path is not set"
      passing=0
  fi
  if [ -n "$(which curl)" ] ; then
      CURL_VERSION=$(curl -V | awk '{print $2}' | head -1 )
      echo "curl is installed version:$CURL_VERSION"
    else
      echo "curl is not installed or the Path is not set"
      passing=0
  fi
  if [ -n "$(which docker)" ] ; then 
      DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed -ne 's/,//p')
      DOCKER_IMAGE_VERSION=$(sudo docker run --rm hyperledger/fabric-tools:$IMAGETAG peer version | sed -ne 's/ Version: //p' | head -1)
      echo "docker images are installed is installed version:$DOCKER_IMAGE_VERSION"
      echo "docker is installed version:$DOCKER_VERSION"
    else
      echo "Docker is not installed or the PATH is not set"
      passing=0
  fi
  if [ -n "$(which docker-compose)" ] ; then 
      DOCKER_COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}' | sed -ne 's/,//p')
      echo "docker-compose is installed version:$DOCKER_COMPOSE_VERSION"
    else
      echo "docker-compose is not installed or the PATH is not set"
      passing=0
  fi
  if [ -n "$(which configtxlator)" ] ; then
      LOCAL_VERSION=$(configtxlator version | sed -ne 's/ Version: //p')
      echo "configtxlator is installed version:$LOCAL_VERSION"
    else
      echo "configtxlator is not installed or the Path is not set"
      echo "You can run: "
      echo "./byfn-simple.sh installBinnaries"
      echo "To install the binnaries"
      passing=0
  fi
  if [ $passing -eq 0 ] ; then
    echo "There are missing Prereqs Exiting"
    exit 1
  fi

  if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
    echo "=================== WARNING ==================="
    echo "  Local fabric binaries and docker images are  "
    echo "  out of  sync. This may cause problems.       "
    echo "==============================================="
  fi

  for UNSUPPORTED_VERSION in $BLACKLISTED_VERSIONS; do
    echo "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      echo "ERROR! Local Fabric binary version of $LOCAL_VERSION does not match this newer version of BYFN and is unsupported. Either move to a later version of Fabric or checkout an earlier version of fabric-samples."
      exit 1
    fi

    echo "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      echo "ERROR! Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match this newer version of BYFN and is unsupported. Either move to a later version of Fabric or checkout an earlier version of fabric-samples."
      exit 1
    fi
  done
}


binaryDownload() {
      local BINARY_FILE=$1
      local URL=$2
      echo "===> Downloading: " ${URL}
      # Check if a previous failure occurred and the file was partially downloaded
      curl ${URL} | tar xz || rc=$?
      
}

binariesInstall() {
  echo "===> Downloading version ${FABRIC_TAG} platform specific fabric binaries"
  binaryDownload ${BINARY_FILE} https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/${ARCH}-${VERSION}/${BINARY_FILE}
  if [ $? -eq 22 ]; then
     echo
     echo "------> ${FABRIC_TAG} platform specific fabric binary is not available to download <----"
     echo
   fi
}

function installBinnaries(){
# if version not passed in, default to latest released version
export VERSION=1.4.0
# if ca version not passed in, default to latest released version
export CA_VERSION=$VERSION
# current version of thirdparty images (couchdb, kafka and zookeeper) released
export THIRDPARTY_IMAGE_VERSION=0.4.14
export ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')")
export MARCH=$(uname -m)
BINARY_FILE=hyperledger-fabric-${ARCH}-${VERSION}.tar.gz
binariesInstall
}


##################################################
###                 low-level (High Detail)    ###
##################################################

###_______________Cert_Generation______________###

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


# This function takes the generated certs and adds the key to the given CA's yaml file
CA1_PRIVATE_KEY=""
CA2_PRIVATE_KEY=""
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


###_____________Artifact_Generation____________###

# This function will create a channel artifact
# $1: ^String -> Output file of the channel file  | default $ARTIFACT_DEFAULT/channel.tx
# $2: ^String -> Channel Name | default $CHANNEL_NAME
# $3: ^String -> profile to use for the genesis generation pulled from the configtx.yaml | default TwoOrgsChannel  
function create_channel_artifact(){
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi
  mkdir -p $(dirname ${1:-$ARTIFACT_DEFAULT/channel.tx})
  echo
  echo "#################################################################"
  echo "### Generating channel configuration transaction 'channel.tx' ###"
  echo "#################################################################"
  set -x
  configtxgen -profile ${3:-TwoOrgsChannel} -outputCreateChannelTx ${1:-$ARTIFACT_DEFAULT/channel.tx} -channelID ${2:-$CHANNEL_NAME}
  
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
  configtxgen -profile ${3:-TwoOrgsOrdererGenesis} -channelID byfn-sys-${2:-$CHANNEL_NAME}  -outputBlock ${1:-$ARTIFACT_DEFAULT}/genesis.block
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



##################################################
###               Medium Detail                ###
##################################################

# This function run eash of the funtion required for generate the Peer and Orderer Certs
function generate_certs(){
    create_certs
    inject_keys
}

# This function will create all the required atifacts for the byfn-simple network
function generate_artifacts(){
    create_channel_artifact $ARTIFACT_DEFAULT/channel.tx $CHANNEL_NAME TwoOrgsChannel
    create_genesisblock_artifact $ARTIFACT_DEFAULT $CHANNEL_NAME TwoOrgsOrdererGenesis
    create_organisation_artifact Org1MSP $ARTIFACT_DEFAULT $CHANNEL_NAME TwoOrgsChannel
    create_organisation_artifact Org2MSP $ARTIFACT_DEFAULT $CHANNEL_NAME TwoOrgsChannel
}

# This function will boot all the containers in the docker-compose.yaml file
function boot_containers(){
    echo boot_containers
    IMAGE_TAG=$IMAGETAG \
    COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME \
    CA1_PRIVATE_KEY=$CA1_PRIVATE_KEY \
    CA2_PRIVATE_KEY=$CA2_PRIVATE_KEY \
    ARTIFACT_DEFAULT=$ARTIFACT_DEFAULT \
    docker-compose -f $COMPOSE_FILE up -d 2>&1
}

# This function will connect to the CLI container and run the ./scripts/script.sh 
# which will then set up the network with the generated config
function run_inner_script(){
  docker exec cli scripts/build-network.sh start 2>&1
}


##################################################
###                  Hi-level (Low Detail)     ###
##################################################

# This function will execute the following steps:
# Step 1: checks that you have correct prerequisites and versions installed
# Step 2: generate the certs and artifacts
# Step 3: boot the containers
# Step 4: configure the network
function up(){
    checkPrereqs
    generate_certs
    generate_artifacts
    boot_containers
    run_inner_script
}

# This function will execute the following steps:
# Step 1: bring down the containers
# Step 2: clean the container images
# Step 3: rm any generated files
function down(){
    echo down
    # stop org3 containers also in addition to org1 and org2, in case we were running sample to add org3
    echo docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_ORG3 down --volumes --remove-orphans
    IMAGE_TAG=$IMAGETAG \
    COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME \
    CA1_PRIVATE_KEY=$CA1_PRIVATE_KEY \
    CA2_PRIVATE_KEY=$CA2_PRIVATE_KEY \
    ARTIFACT_DEFAULT=$ARTIFACT_DEFAULT \
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


eval "$@"

exit


