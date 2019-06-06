# Chaincode

This chaincode project aims to simulate a simple supply chain example. We explore how to store objects and some business logic on the ledger with this chaincode. We have also configured the chaincode to work with a mock stub. This means you will not have to run a hyperledger network to test your chaincoding skills.


# Key Files
### demo.ts
This file contains all the chaincode to the simple supply chain. There are 4 main objects that are a part of this network. 
- GPU
- Business
- Order
- LineItem

### test.spec.ts
This file initiates the mock stub and will run a sequence on chaincode functions to simulate an order of some GPUs. The key sequence of events are:
- Initializing the network objects
- Org1 Creates an order for 2 GPUs
- Org2 fills the order from their stock
- The order progress through a sequence of states "TRANSIT" "DELIVERED"
- Org2 sells the gpu to a customer.

Once the simulation is complete we look at the history of one of the GPU's. This lets us see all the states of the gpu. The states include all the previous owners of the gpu. 

# Starting the Mock Stub
If you want to run the Mock Stub locally and run some of your own tests you will need to make sure you have node 8 installed and npm. Once you have these dependencies you will want to run. 
``` sh
npm install
```

This will install all the requirements for the project.
Now that we have all the dependencies install we can start the node watcher. This will watch the file and will compile the typescript and run the tests when ever you save the file. 
``` sh
npm run watch-ts
```
