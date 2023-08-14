import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-contract-sizer";
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/A1kOgx6h_A2I6-pGTuuxTpE9yiA2YS0m",
      accounts: [ "cc62d5d460834f2661b6f8f610f609682f1d0e74d25c65dc54afb35513af1304" ],
    },
  },
};

export default config;
