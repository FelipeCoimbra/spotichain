#!/bin/bash

ACCESSNODE_DIR=/ether/AccessNode
MINER_DIR=/ether/Miner0
BOOTNODE_DIR=/ether/BootNode

##
## Start Boot node
##
bootnode --addr $HOSTNAME --nodekey=$BOOTNODE_NODEKEY_FILE > $BOOTNODE_DIR/enode &

##
## Get bootnode enode
##
while [[ x$BOOT_ENODE == x ]] ; do
    BOOT_ENODE=$(head -n 1 $BOOTNODE_DIR/enode)
done

##
## Start Access Node
##
geth --nousb \
--datadir $ACCESSNODE_DIR \
--port 30301 \
--rpc \
--rpcport "8545" \
--rpccorsdomain "*" \
--networkid $NETWORKID \
--allow-insecure-unlock \
--bootnodes $BOOT_ENODE \
2>>$ACCESSNODE_DIR/geth.log &

##
## Start Miner
##
geth --datadir=datadir \
--networkid $NETWORKID \
--bootnodes $BOOT_ENODE \
--mine \
--minerthreads=1 \
--etherbase=0 \
2>>$BOOTNODE_DIR/geth.log &

while [[ true ]] ; do sleep 1; done
