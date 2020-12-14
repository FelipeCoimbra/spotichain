# spotichain
A blockchain-powered descentralized music work sharing service. 

## Instructions

Build the Access Node image with

```sh
docker build -f ./network/AccessPoint.Dockerfile -t "spotichain_access"
```

Then spawn a container with AccessNode + BootNode (used for node discovery) + 1 Miner with

```sh
docker run -d -p 8545:8545/tcp --name SpotichainAccess spotichain_access
```
