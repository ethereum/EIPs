# PBM Solidity implementation

## Description

We provide a list of sample PBM implementation for reference.

### Provided Contracts and Tests

<!-- TBD: Explain the folder structure -->

- `contracts/preloaded-pbm/XXXX.sol` - PBMRC1 implementation contract to demonstrate preloaded PBMs
- `contracts/non-preloaded-pbm/XXXX.sol` - Interface contract
<!-- - `contracts/attest-unlock-pbm/XXXX.sol` - contract to demonstrate a 3rd party attestation to allow unwrap of a PBM -->
- `contracts/XXXX.sol` - Interface contract
- `contracts/ERC20.sol` - ERC20 token contract for unit tests
- `test/XXXXX.js` - Unit tests for livecycle of the PBM implementation

### Used javascript based testing libraries for solidity

<!-- TBD: Fill this up with libraries used -->

- `hardhat`: hardhat allows for testing of contracts with JavaScript via Mocha as the test runner
- `chai`: Chai is an assertion library and provides functions like expect.
- `ethers`: This is a popular Ethereum client library. It allows you to interface with blockchains that implement the Ethereum API.

### Compile and run tests with hardhat

<!-- TBD: Improve this with nix file -->

We provide the essential steps to compile the contracts and run provided unit tests
Check that you have the latest version of npm and node via `npm -version` and `node -v` (should be a LTS version for hardhat support)

1. Check out project
2. Go to folder and initialise a new npm project: `npm init -y`. A basic `package.json` file should occur
3. Install Hardhat as local solidity dev environment: `npx hardhat`
4. Select following option: Create an empty hardhat.config.js
5. Install Hardhat as a development dependency: `npm install --save-dev hardhat`
6. Install further testing dependencies:
   `npm install --save-dev @nomiclabs/hardhat-waffle @nomiclabs/hardhat-ethers ethereum-waffle chai  ethers solidity-coverage`
7. Install open zeppelin contracts: `npm install @openzeppelin/contracts`
8. add plugins to hardhat.config.ts:

```
require("@nomiclabs/hardhat-waffle");
require('solidity-coverage');
```

9. Adding commands to `package.json`:

```
"scripts": {
    "build": "hardhat compile",
    "test:light": "hardhat test",
    "test": "hardhat coverage"
  },
```

9. run `npm run build`
10. run `npm run test`
