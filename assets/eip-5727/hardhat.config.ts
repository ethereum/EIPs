import '@nomicfoundation/hardhat-toolbox'
import { HardhatUserConfig } from 'hardhat/types'

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.17',
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
}

export default config
