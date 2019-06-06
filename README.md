# byfn-simple

If you have not completed `tutorial-01` we suggest going back and at least get the network running. 
``` sh
./byfn-simple.sh up
```
This will be required to deploy your chaincode to the network. 

If you only want to play with some chaincode then it is not required that you have this running. 

## Tutorial-02
In this tutorial we will be running and testing typescript chaincode both on the network and using a Mock Stub.

Once you have cloned this repo and have it locally, check that you are on the `tutorial-02` branch. 

### 1) Running the Mock Stub

Navigate to the chaincode dir
``` sh
cd chaincode
```
Install the node dependencies
``` sh
npm install
```
Run watch
``` sh
npm run watch-ts
```

You now have the chaincode in `/chaincode/src/demo.ts` running using a mock stub. Try adding an extra `console.log("<your name>")` at the start of the Invoke function. Once you save it the test should run again and you should be able to see your name in the outputs. 

You can now quickly experiment with chaincode and create scenarios in the `/chaincode/src/test.spec.ts` to test your chaincode.

### 2) Install the chaincode

To start you will want to run 
``` sh 
./byfn-simple.sh up
``` 
This will boot the network we covered in `tutorial-01` and install the chaincode found in the `chaincode/` folder. 

You can then connect to the cli container by running
``` sh
docker exec -it cli bash
```
Once in the cli container we can run functions of the installed chaincode. 
``` sh 
(inside cli container)
# invoke functions are run on peer 0 org 1 by default
./scripts/test-network.sh invoke createBusiness buz-1 HolyTech
# this will query the value of buz-1 on peer 0 org 1
./scripts/test-network.sh query 0 1 getState buz-1
```

We have also written a bash script that will run the same simulation as the typescript test file. To run this test run the following.
``` sh
(inside cli container)
./scripts/test_sc.sh
```

### 3) Updating the chaincode

To push your local chaincode updates to the hyper-ledger network you can run 
``` sh
(outside cli container)
./byfn-scripts/cdp-ext.sh
```
This will take what ever is in the chaincode container and deploy it as an update into the running hyper-ledger network. 



