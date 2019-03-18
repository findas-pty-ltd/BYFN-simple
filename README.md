# byfn-simple

This repository aims to reduce the Hyperledger Fabric "Build Your First Netowrk" exmaple down to its simplest form.

### Repository 
- bin
    - Contains the compiled binaries created by the fabric team.
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
$ git clone https://github.com/findas-pty-ltd/BYFN-simple byfn-simple
$ cd byfn-simple
```
Once you have download the repository and are in the repository folder you can run
```sh
$ ./byfn-simple.sh binaryDownload
$ ./byfn-simple.sh pullContainers
```
This will download the binnaries for your machine and will pull the required docker containers for the fabric network.
Once this has completed you can add the binnaries to your path and test them by running
```sh
$ export PATH=$PATH:$PWD/bin
$ ./byfn-simple.sh checkPrereqs
```

Now that the environment is ready we can start building the network.

### Step 2 Testing
Run the full byfn to test if the network will boot
```sh
$ ./byfn-simple.sh up
```
Once you have byfn running cleanly through run
```sh
$ ./byfn-simple.sh down
```

The following steps will break down what the byfn script is doing to boot your first network

### Step 3 Certs

byfn starts by looking at the crypto-config.yaml file and generates Organisation certificates for that network structure.
```sh
$ ./byfn-simple.sh create_certs [crypto-config.yaml path]
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
$ ./byfn-simple.sh create_channel_artifact [Output File] [Channel Name] [Profile From configtx.yaml]
$ ./byfn-simple.sh create_organisation_artifact [MSP name] [Output Folder] [Channel Name] [Profile From configtx.yaml] 
$ ./byfn-simple.sh create_genisiblock_artifact [Output Folder] [Channel Name] [Profile From configtx.yaml]
```
These functions all use the configtxgen binnary


### Step 5 Booting The Network

Now that we have all the certs and artifacts generated we can boot all the containers for the network.
```sh
$ ./byfn-simple.sh boot_network
```
To check all the containers were created you can run
```sh
$ docker ps
```

### Step 6 Configuring the network

To Configure the network you will need to connect to the CLI container by running
```sh
$ docker exec -it cli bash
```

Now that you are in the CLI if you run the `ls` command you should be able to see these folders
- channel-artifacts  
- crypto-config
- chaincode
- scripts

Now you'll want to setup the channel by running
```sh
$ ./scripts/build-network.sh init_channel
```
This will create our channel called "mychannel" and join all peers to it.
Next we'll want set up our Anchor peers so run
```sh
$ ./scripts/build-network.sh init_anchors
```
This will set peer0 of org1 and peer0 of org2 as our anchor peers.
And now you'll need to install and instantiate the chaincode by running 
```sh
$ ./scripts/build-network.sh init_chaincode
```
This will create 2 entities A and B, giving entity A a total of 100 and entity B a total of 200.


### Step 7 Testing the network

Now that the network is configured and running, you can test it while connected to the cli container by running
```sh
$ ./scripts/test-network.sh test_chaincode
```
This will first query peer0 of org1 with an expected response. Next it will run a transaction by sending 10 from A to B.
Then finally it will query peer1 of org2 to check that the transaction was successful.

## Prerequisites
##### Summary
- Docker and Docker Compose 17.06.2-ce +
- Node.js Runtime and NPM   8.x
- Go Programming Language   1.11.x
- Python                    2.7  
##### Details
https://hyperledger-fabric.readthedocs.io/en/latest/prereqs.html

