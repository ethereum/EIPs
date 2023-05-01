import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      // viaIR: true, // needed for stack depth..
      optimizer: {
        enabled: true,
        runs: 1
      },
    },
  },
};

export default config;
