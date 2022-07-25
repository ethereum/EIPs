import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "hardhat-tracer";
import "hardhat-contract-sizer";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

const argv = require("yargs/yargs")()
  .env("")
  .options({
    ci: {
      type: "boolean",
      default: false,
    },
    coverage: {
      type: "boolean",
      default: false,
    },
    gas: {
      alias: "enableGasReport",
      type: "boolean",
      default: false,
    },
    mode: {
      alias: "compileMode",
      type: "string",
      choices: ["production", "development"],
      default: "development",
    },
    compiler: {
      alias: "compileVersion",
      type: "string",
      default: "0.8.9",
    },
    coinmarketcap: {
      alias: "coinmarketcapApiKey",
      type: "string",
    },
    trace: {
      alias: "eventTrace",
      type: "boolean",
      default: false,
    },
  }).argv;

if (argv.enableGasReport) {
  require("hardhat-gas-reporter");
}

if (argv.eventTrace) {
  require("hardhat-tracer");
}

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.15",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    coverage: {
      url: "http://127.0.0.1:8555", // Coverage launches its own ganache-cli client
    },
  },
  gasReporter: {
    enabled: argv.enableGasReport,
    currency: "USD",
    gasPrice: 40,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
