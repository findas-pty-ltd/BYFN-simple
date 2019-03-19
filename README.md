# byfn-simple

This repository aims to reduce the Hyperledger Fabric "Build Your First Netowrk" example down to its 
simplest form. The reository also aims to break down the learning of fabric into four levels of detail. 
The lowest detail of calling the `./byfn-simple.sh up` and the highest detail of calling the fabric 
binaries themselves. The Steps bellow will hopefully guide you through these levels leaving you with a
better understanding of the step required to build your first fabric network.

### In This Repository 
- configtx.yaml 
    - Contains the channel configuration - one configtx per channel. 
- crypto-config.yaml
    - Network tapolagy, is used for generaing certificates and permissions for each entity in the network.
- docker-compose.yaml
    - used for brining up containers (cli, orderer, peers, ca).
- byfn-simple.sh
    - The script containing all the required commands to build and run the network.

# Steps

### Step 1 Prep
Install the prerequisites listed bellow
Then clone this repository by running the command.
```sh
git clone https://github.com/findas-pty-ltd/BYFN-simple byfn-simple
cd byfn-simple
```
Once you have download the repository and are in the repository folder you can run
```sh
./byfn-simple.sh binaryDownload
./byfn-simple.sh pullContainers
```
This will download the binnaries for your machine and will pull the required docker containers for the fabric network.
Once this has completed you can add the binnaries to your path and test them by running
```sh
export PATH=$PATH:$PWD/bin
./byfn-simple.sh checkPrereqs
```

Now that the environment is ready we can start building the network.

### Step 2 Testing
Run the full byfn to test if the network will boot
```sh
./byfn-simple.sh up
```
Once you have byfn running cleanly through run
```sh
./byfn-simple.sh down
```

The following steps will break down what the byfn script is doing to boot your first network

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
- Organisation MSPs
- GenisisBlocks
 
```sh
./byfn-simple.sh create_channel_artifact ./channel-artifacts/channel.tx mychannel TwoOrgsChannel
./byfn-simple.sh create_genesisblock_artifact ./channel-artifacts/ mychannel TwoOrgsOrdererGenesis
./byfn-simple.sh create_organisation_artifact Org1MSP ./channel-artifacts/ TwoOrgsChannel
./byfn-simple.sh create_organisation_artifact Org2MSP ./channel-artifacts/ TwoOrgsChannel

```

### Step 5 Booting The Network

Now that we have all the certs and artifacts generated we can boot all the containers for the network.
```sh
./byfn-simple.sh boot_containers
```
To check all the containers were created you can run
```sh
docker ps
```
There should be 6 docker containers running

Note: To debug containers that did not boot run
```sh
docker ps -a
```
You should be able to see the container that did not boot. You can then use it's container id to view it's logs
and hopefully figure out why it crashed
```sh
docker logs -f <container id> 
```

### Step 6 Configuring the network

To Configure the network you will need to connect to the CLI container by running
```sh
docker exec -it cli bash
```

Now that you are in the CLI if you run the `ls` command you should be able to see these folders
- channel-artifacts  
- crypto-config
- chaincode
- scripts

Now we'll want to create the channel by running
```sh
./scripts/build-network.sh createChannel 0 1
```
This will create our channel called "mychannel".
Now we want to join peers to the channel using the commands
```sh
./scripts/build-network.sh joinChannel 0 1 #peer0 org1
./scripts/build-network.sh joinChannel 1 1 #peer1 org1
./scripts/build-network.sh joinChannel 0 2 #peer0 org2
./scripts/build-network.sh joinChannel 1 2 #peer1 org2
```
Next we'll want set up our Anchor peers so run
```sh
./scripts/build-network.sh updateAnchorPeers 0 1 #peer 0 org1
./scripts/build-network.sh updateAnchorPeers 0 2 #peer 0 org2
```
This will set peer0 of org1 and peer0 of org2 as our anchor peers.
And now we'll want to install chaincode onto our peers by running these 4 commands
```sh
./scripts/build-network.sh installChaincode 0 1 
./scripts/build-network.sh installChaincode 1 1
./scripts/build-network.sh installChaincode 0 2
./scripts/build-network.sh installChaincode 1 2
```
And now the chaincode has to be instantiated, this done by instantiating the chaincode on 1 peer.
```sh
./scripts/build-network.sh instantiateChaincode 0 2
```
This will create 2 entities A and B, giving entity A a total of 100 and entity B a total of 200.


### Step 7 Testing the network

Now that the network is configured and running, you can test it while connected to the cli container by running
```sh
./scripts/test-network.sh chaincodeQuery 0 1 100
```
This command will execute the chaincode on peer1.org1, it will query the state of entity A which is expecting a result of 100.
Now we can run a transaction
```sh
./scripts/test-network.sh chaincodeInvoke mychannel mycc 0 1 0 2
```
This will execute the chaincode on a peer and send 10 from entity A to entity B, so now A should have 90 and B should have 210
Finally we'll want to check that our transaction was successful so we can run the query command again for entity A.
```sh
./scripts/test-network.sh chaincodeQuery 0 1 90
```
If the query response for enity A returns a value of 90, then the transaction was successful and stored on the ledger.

## Prerequisites
##### Summary
- Docker and Docker Compose 17.06.2-ce +
- Node.js Runtime and NPM   8.x
- Go Programming Language   1.11.x
- Python                    2.7  
##### Details
https://hyperledger-fabric.readthedocs.io/en/latest/prereqs.html

