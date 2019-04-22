# byfn-simple

## Summary

This repository aims to reduce the Hyperledger Fabric tutorial "Build Your First Network" down to its 
simplest form and to maximuze the learning. This repository breaks down the Fabric tutorial into four levels of detail. 

1. The high level is the most simple and is called with `./byfn-simple.sh up` 
2. The medium level increases the learning opportunity the `./byfn-simple.sh` script is called with:
    - generate_certs
    - generate_artifacts
    - boot_containers
    - run_inner_script
3. The low level maximises the learning and the `./byfn-simple.sh` script is called with:
    - create_certs
    - inject_keys
    - create_channel_artifact
    - create_genesisblock_artifact
    - create_organisation_artifact

It is also possible to call all the binaries directly once you fully understand the build logic.  The Steps below guide you through these levels providing you with a
better understanding of the steps required to build your first Fabric network.

### In This Dir 

- configtx.yaml 
    - Contains the channel configuration - one configtx per channel. 
- crypto-config.yaml
    - Contains the Network topology and is used for generaing certificates and permissions for each entity in the network.
- docker-compose.yaml
    - used for starting and stopping docker containers (cli, orderer, peers, ca).
- byfn-simple.sh
    - The main script containing all the required commands to build and run the network.

## Prerequisites

#### Docker 17.06.2-ce or above and Docker Compose 1.14.0 or above

To Install Go To https://www.docker.com/get-started


#### Node.js Runtime and NPM   8.x

To Install NVM ( Node Version Manager ) Go To https://nodesource.com/blog/installing-node-js-tutorial-using-nvm-on-mac-os-x-and-ubuntu/

To Select Version 8 Run

```sh
nvm use 8
```

#### Go Programming Language   1.11.x

To Install Go To https://golang.org/dl/

Download your platform's version of golang 

Once you have downloaded and either installed or extracted the golang download then you will need to add the golang bin folder to your path

```sh
export GOPATH=/path_to_your_go_download/ # you must fill in the path to the go download
export PATH=$PATH:$GOPATH/bin  
```

#### Python 2.7  If you are on Ubuntu 16.04

To Install run 

```sh
sudo apt-get install python
```


#### To check you have all the prereqs

Run the following version commands

```sh
go version
python --version
docker --version
docker-compose --version
```

If all of these run and are the correct versions you are ready to begin the byfn-simple tutorial as outlined below


#### If you are having any problems you can also use the Hyperledger Fabric prereqs doc below 

https://hyperledger-fabric.readthedocs.io/en/latest/prereqs.html


# Steps

### Step 1 Prep
Install the prerequisites listed below

Then clone this repository by running the command.

```sh
git clone https://github.com/findas-pty-ltd/BYFN-simple byfn-simple
cd byfn-simple
```

Once you have download the repository and are in the 'byfn-simple' repository folder  run

```sh
./byfn-simple.sh binaryDownload
./byfn-simple.sh pullContainers
```

This will download the binaries for your machine and pulls the required docker containers for the Fabric network.

Once this has completed add the binaries folder to your PATH and test

```sh
export PATH=$PATH:$PWD/bin
./byfn-simple.sh checkPrereqs
```

The environment is now ready you can start building the network.

**Note :** If you are getting permission denied error when running any of the scripts, you will need to run

```sh
chmod 777 ./byfn-simple.sh
chmod 777 ./scripts/test-network.sh
chmod 777 ./scripts/build-network.sh
chmod 777 ./scripts/utils.sh
```


### Step 2 Testing

Run the high-level byfn-simple script to test if the network will boot

```sh
./byfn-simple.sh up
```

Once you have byfn running cleanly then bring it back down

```sh
./byfn-simple.sh down
```

Now run the low-level byfn-simple script to better unerstand the build process.

**Note : ** If you are getting ERROR: could not connect to docker deamon this could be becuase you need to add docker to sudo list.

```sh
sudo groupadd docker
sudo usermod -aG docker $USER
```
Then sign out and sign back in for these changes to take effect. This will make is so you don't need to use sudo for docker commands.

### Step 3 Certs

byfn starts by looking at the crypto-config.yaml file and generates Organisation certificates for that network structure.

```sh
./byfn-simple.sh create_certs ./crypto-config.yaml 
```

You sould be able to see a new folder crypto-config which the container will then join volumes with. 

This function is using the cryptogen binnary to create these files

### Step 4 Artificats

After the certs have been generated we now need to generate the network artifacts 

These include:
- channel MSPs
- GenisisBlocks
- Organisation MSPs
 
```sh
./byfn-simple.sh create_channel_artifact ./channel-artifacts/channel.tx mychannel TwoOrgsChannel
./byfn-simple.sh create_genesisblock_artifact ./channel-artifacts/ mychannel TwoOrgsOrdererGenesis
./byfn-simple.sh create_organisation_artifact Org1MSP ./channel-artifacts/ mychannel TwoOrgsChannel
./byfn-simple.sh create_organisation_artifact Org2MSP ./channel-artifacts/ mychannel TwoOrgsChannel

```

### Step 5 Booting The Network

Now that we have all the certs and artifacts are generated you can start/boot all the containers for the network.

```sh
./byfn-simple.sh boot_containers
```

To check all the containers are running

```sh
docker ps
```

There should be 6 docker containers running
- cli
- orderer
- peer0 org1
- peer1 org1
- peer0 org2
- peer1 org2

**Note:** To debug containers that did not boot, run

```sh
docker ps -a
```

You should be able to see the container that did not boot. You can then use it's container 'id' to view it's logs
and hopefully figure out why it crashed

```sh
docker logs -f <container id> 
```

### Step 6 Configure the network

To Configure the network you will need to connect to the CLI container by running

```sh
docker exec -it cli bash
```

Once connected to the CLI container run the `ls` command and you should see these folders
- channel-artifacts  
- crypto-config
- chaincode
- scripts

Now you'll want to create the channel by running

```sh
./scripts/build-network.sh createChannel 0 1
```

This will create a channel called "mychannel".

Now join the peers to the channel using the commands

```sh
./scripts/build-network.sh joinChannel 0 1 #peer0 org1
./scripts/build-network.sh joinChannel 1 1 #peer1 org1
./scripts/build-network.sh joinChannel 0 2 #peer0 org2
./scripts/build-network.sh joinChannel 1 2 #peer1 org2
```

Next you'll want to set up the Anchor Peers so run

```sh
./scripts/build-network.sh updateAnchorPeers 0 1 #peer 0 org1
./scripts/build-network.sh updateAnchorPeers 0 2 #peer 0 org2
```

This will set peer0 of org1 and peer0 of org2 as the Anchor Peers.

And now you'll want to install chaincode onto the Peers by running these 4 commands

```sh
./scripts/build-network.sh installChaincode 0 1 
./scripts/build-network.sh installChaincode 1 1
./scripts/build-network.sh installChaincode 0 2
./scripts/build-network.sh installChaincode 1 2
```

And now instantiate the chaincode, this will run the Init function creating the starting state of the blockchain.

You can view the 'Init' function [here](https://github.com/findas-pty-ltd/BYFN-simple/blob/master/chaincode/simple_chaincode.go#L37 "Location of Init Function")

```sh
./scripts/build-network.sh instantiateChaincode 0 2
```

This will create 2 entities, A and B, giving entity 'A' a total of 100 tokens and entity 'B' a total of 200 tokens.


### Step 7 Testing the network

Now  the network is configured and running it is time to execute the Query function in the chaincode to make sure entities 'A' and 'B' exist.

This is done by running

```sh
./scripts/test-network.sh chaincodeQuery 0 1 100
```

This executes the chaincode on peer0.org1, it will query the state of entity 'A' and states a result of 100 tokens is expected.

Now you can run a transaction, let's send 10 tokens from entity 'A' to entity 'B'

```sh
./scripts/test-network.sh chaincodeInvoke mychannel mycc 0 1 0 2
```

The above command executes the chaincode on both peer0 org1 and peer0 org2

This will execute the chaincode on a peer and send 10 from entity A to entity B, so now A should have 90 and B should have 210.

Finally we'll want to check that our transaction was successful so we can run the query command again for entity A

```sh
./scripts/test-network.sh chaincodeQuery 0 1 90
```
If the query response for enity 'A' returns a value of 90, then the transaction was successful and was stored on the ledger.
