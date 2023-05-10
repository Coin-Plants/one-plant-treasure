# Hardhat Standard Environment

This project demonstrates a standard Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```

```Get Started
npm install

```Compilation
npx hardhat compile

```Depolyment
npx hardhat run scripts/deploy.js --network <NETWORK_NAME>
npx hardhat run scripts/deployProxy.js --network <NETWORK_NAME>

```Verification
npx hardhat verify <ADDRESS> --network <NETWORK_NAME>

```Test
npx hardhat test
npx hardhat test test/script.js

--ENV File Structure

ETHERSCAN_API_KEY   = <YOUR SCAN API KEY>
BINANCE_API_KEY     = <YOUR SCAN API KEY>
POLYGONSCAN_API_KEY = <YOUR SCAN API KEY>
SNOWTRACE_API_KEY   = <YOUR SCAN API KEY>

ETHEREUM_RPC_URL    = "https://rpc.ankr.com/eth"
BINANCE_RPC_URL     = "https://bsc-dataseed1.binance.org"
POLYGON_RPC_URL     = "https://polygon-rpc.com"
AVALANCHE_RPC_URL   = "https://api.avax.network/ext/bc/C/rpc"

GOERLI_RPC_URL      = "https://rpc.ankr.com/eth_goerli"
SEPOLIA_RPC_URL     = "https://eth-sepolia.g.alchemy.com/v2/3ltQ_39-Ih6EU5-082Qdv5Qg8v4hjriP"
BNBTEST_RPC_URL     = "https://bsc-testnet.public.blastapi.io"
MUMBAI_RPC_URL      = "https://rpc.ankr.com/polygon_mumbai"
FUJI_RPC_URL        = "https://rpc.ankr.com/avalanche_fuji"

PRIVATE_KEY         = <YOUR WALLET PRIVATE KEY>