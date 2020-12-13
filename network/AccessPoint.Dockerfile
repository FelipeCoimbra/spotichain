FROM ethereum/client-go:alltools-stable

WORKDIR ether/
# Genesis block setup
COPY genesis.json ./genesis.json
RUN bootnode --help
RUN geth --nousb --datadir "./AccessNode" init "./genesis.json"
RUN geth --nousb --datadir "./Miner0" init "./genesis.json"

# WORKDIR ether/AccessNode
# RUN geth --nousb \
# --datadir . \
# --port 30301 \
# --nodiscover \
# --rpc \
# --rpcport "8545" \
# --rpccorsdomain "*" \
# --networkid 1234 \
# --allow-insecure-unlock \
# 2>>./geth.log

# Run Bootnode
# WORKDIR ether/boot
# RUN bootnode
ENTRYPOINT ['geth']