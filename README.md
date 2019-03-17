# BYFN-simple

This repository aims to reduce the Hyperledger Fabric "Build Your First Netowrk" exmaple down to its simplest form.

### Repository 
- bin
    - Contains the compiled binanairs created by the fabric team.
- configtx.yaml 
    - Contains the channel configuration - one configtx per channel. 
- crypto-config.yaml
    - Network tapolagy, is used for generaing certificates and permissions for each entity in the network.
- docker-compose.yaml
    - used for brining up containers (cli, orderer, peers, ca).
- BYFN.sh
    - The script containing all the required commands to build and run the network.

# Steps

### Step 1 Prep
Install the prerequisites listed bellow
and
add ./bin folder to your path
```sh
$ export PATH=$PATH:$PWD/bin
```
To test you should be able to run
```sh
$ which cryptogen
```

### Step 2 Testing
Run the full byfn to test if the network will boot
```sh
$ ./BYFN.sh up
```
Once you have Byfn running cleanly through
Run
```sh
$ ./BYFN.sh down
$ ./BYFN.sh clean
```

The following steps will break down what the BYFN script is doing to boot your first network

### Step 3 Certs
BYFN starts by looking at the crypto-config.yaml file and generates Organisation certificates for that network structure.
```sh
$ ./BYFN.sh create_certs x
```
You sould be able to see a new folder crypto-config which the container will then join volumes with. 

This function is using the cryptogen binnary to create these files

### Step 4 Artificats
After the certs have been generated we now need to generate the network artifacts 
These include:
- channel MSPs
- Organisation MSPs
- Genisiblocks
```sh
$ ./BYFN.sh create_channel_artifact x
$ ./BYFN.sh create_organisation_artifact x
$ ./BYFN.sh create_genisiblock_artifact x
```
These functions use the repective binnaries
- x
- y
- z


### Step 5 Booting The Network
Now that we have all the certs and artifacts generated we can boot all the containers for the network.
```sh
$ ./BYFN.sh boot_network x
```
To check all the containers were created you can run
```sh
$ docker ps
```

### Step 6 Configuring the network



## Prerequisites
##### Summary
- Docker and Docker Compose 17.06.2-ce +
- Node.js Runtime and NPM   8.x
- Go Programming Language   1.11.x
- Python                    2.7  
##### Details
https://hyperledger-fabric.readthedocs.io/en/latest/prereqs.html

