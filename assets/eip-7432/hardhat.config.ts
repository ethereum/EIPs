import 'solidity-coverage'
import 'hardhat-spdx-license-identifier'
import '@nomicfoundation/hardhat-toolbox'

module.exports = {
  solidity: {
    version: '0.8.9',
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  mocha: {
    timeout: 840000,
  },
  gasReporter: {
    enabled: true,
    excludeContracts: ['contracts/mocks'],
    gasPrice: 100,
    token: 'MATIC',
    currency: 'USD',
  },
  spdxLicenseIdentifier: {
    overwrite: false,
    runOnCompile: true,
  },
}