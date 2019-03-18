# Scripts

This folder will be joined to the CLI container


### In This Folder
- bash-settings.cfg
    - This file contains most of the default variables we extracted these variables into a .cfg file so the interal scripts and exteranl script could share the config.
- build-network.sh
    - This file is used to configure the network once the network has been booted
- test-network.sh
    - This file is used once the network is configure and the chaincode is installed. It can be used to query the blockchain and invoce chaincode.
- utils.sh
    - This file contains functions that both the build-network.sh and test-network.sh need to operated.

