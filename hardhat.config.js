require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const INFURA_API_KEY = process.env.INFURA_API_KEY || "ae5d24b89c9d40518512cf4d5d122837";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "Z2I74PM9TS94NU68S222E324GE67N6UX3G";

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      chainId: 1337
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    mainnet: {
      url: "https://go.getblock.us/ac5d5218a3964761bbca16703183ba9c",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 1
    },
    sepolia: {
      url: "https://ethereum-sepolia-rpc.publicnode.com",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 11155111,
      timeout: 60000
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};
