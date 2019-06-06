# Scripts

This folder is mapped to the CLI container and contains scripts that are intended to be run inside the CLI container.


### In This Dir
- bash-settings.cfg
    - This file contains most of the default variables we extracted these variables into a .cfg file so the internal scripts and external script could share the config.
- build-network.sh
    - This file is used to configure the network once the network has been booted
- test-network.sh
    - This file is used once the network is configure and the chaincode is installed. It can be used to query the blockchain and invoke chaincode.
- utils.sh
    - This file contains functions that both the build-network.sh and test-network.sh need to operated.
- test_sc.sh
    - This file will run the same sequence of events as the /chaincode/src/test.spec.ts except on the a real network.


