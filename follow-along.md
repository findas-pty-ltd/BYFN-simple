# Follow Along


### Step 1 - Preperation
We first want to quickly start our network to see if everything is working normally
```sh
./byfn-simple.sh up
```
This will automatically start all the containers in the network and configure them all. Our blockchain network is running! 
Now that we know everything is working, lets bring the nework down so we can manaully build our blockchain.
```sh
./byfn-simple.sh down
```
### Step 2 - Generating certs & artifacts
The first thing we need to do when building our network is creating our certificates, we do this by running
```sh
./byfn-simple.sh generate_certs
```
This will create all our certificates for our peers and our orderer.
Next we want to create the channel artifacts, this is done by running
```sh
./byfn-simple.sh generate_artifacts
```
This will create our genesis block, channel.tx and Org anchor MSPs.

### Step 3 - Starting the containers
Now that we have all our certificates and channel configuration set up, lets start our network containers
```sh
./byfn-simple.sh boot_containers
```
Once this is completed, there should be 6 containers running, we can check this by running 
```sh
docker ps
```
A list of 6 running containers should be displayed.
For this network, we have 4 peers running, 1 orderer and 1 cli container.

### Step 4 - Create channel
Our containers are running, but not talking to eachother, so now we need to configure the network.
First we need to get inside of our cli container, the cli container will be our interface into the network.
We can get inside the cli by running 
```sh
docker exec -it cli bash
```
We are now running commands from the cli.
The first thing we need to do when configuring the network is creating a channel
```sh
./scripts/build-network.sh init_channel
```
This will first create a channel called "mychannel", it will need connect all peers in our network to that channel.

### Step 5 - Anchors
In order for our peers to be able to connect with each other, we need to set up our anchor peers
```sh
./scripts/build-network.sh init_anchors
```
This will set peer0 of Org1 and peer0 of Org2 as our anchors

### Step 6 - Install & Instantiate chaincode
Now it's time to setting up our chaincode on each of our peers, we do this by running
```sh
./scripts/build-network.sh init_chaincode
```
This will install the chaincode on all the peers and then instantiate it on 1 of the peers, creating 2 entities, 'A' with 100 tookens and 'B' with 200 tokens.

### Step 7 - Test the chaincode
We now have our containers running, network configured and chaincode ready, we can now test the chaincode by executing a transation
```sh 
./scripts/test-network.sh test_chaincode
```
This will first query entity 'A' and return its token count. Next it will run a transation, sending 10 tokens from entity 'A' to entity 'B' and then finally query entity 'A' again to see if the transation was successful.

