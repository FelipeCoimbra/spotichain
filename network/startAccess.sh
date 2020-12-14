#!/bin/bash

ACCESSNODE_DIR=/ether/AccessNode
BOOTNODE_DIR=/ether/BootNode

##
## Start Boot node
##
bootnode --addr $HOSTNAME:30301 --nodekey=$BOOTNODE_NODEKEY_FILE > $BOOTNODE_DIR/enode &

##
## Get bootnode enode
##
while [[ x$BOOT_ENODE == x ]] ; do
    BOOT_ENODE=$(head -n 1 $BOOTNODE_DIR/enode)
done

##
## Setup Access Node account
##
geth --nousb \
--nodiscover \
--datadir $ACCESSNODE_DIR \
--networkid $NETWORKID \
account new --password $ACCESSNODE_DIR/accesspwd \
2>>$ACCESSNODE_DIR/geth.log

##
## Start Access Node + Mining thread
##
geth --nousb \
--datadir $ACCESSNODE_DIR \
--port 30302 \
--http \
--http.addr "0.0.0.0" \
--http.port "8545" \
--http.api eth,web3,personal,net \
--http.corsdomain "*" \
--networkid $NETWORKID \
--allow-insecure-unlock \
--bootnodes $BOOT_ENODE \
--mine \
--miner.threads=1 \
--miner.etherbase=0 &

echo "Spotichain ready for access!"
while [[ true ]] ; do sleep 1; done
