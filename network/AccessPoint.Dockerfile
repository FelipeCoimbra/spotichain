FROM ethereum/client-go:alltools-stable

WORKDIR ether/
# Genesis block setup
COPY genesis.json ./genesis.json
RUN geth --nousb --datadir "./AccessNode" init "./genesis.json"
RUN geth --nousb --datadir "./BootNode" init "./genesis.json"

# Access credentials
COPY accesspwd AccessNode/accesspwd

# Bootnode key
COPY bootnode.nodekey BootNode/bootnode.nodekey
ENV BOOTNODE_NODEKEY_FILE=/ether/BootNode/bootnode.nodekey

# ENV variables
ENV NETWORKID=3510573

COPY ./startAccess.sh ./startAccess.sh
CMD sh "./startAccess.sh"