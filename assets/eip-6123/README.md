# SDC Solidity implementation

## Description

The reference SDC implementation can be unit tested with hardhat to understand the trade process logic.

### Compile and run tests with hardhat

We provide the essential steps to compile the contracts and run the provided unit tests.

### Provided Contracts and Tests

- `contracts/ISDC.sol` - Interface contract
- `contracts/SDC.sol` - SDC abstract contract for an OTC Derivative
- `contracts/SDCPledgedBalance.sol` - SDC full implementation for an OTC Derivative
- `contracts/IERC20Settlement.sol` - Interface (extending the ERC-20) for settlement tokens used in `SDCPledgedBalance`.
- `contracts/ERC20Settlement.sol` - Mintable settlement token contract implementing `IERC20Settlement` for unit tests
- `test/SDCTests.js` - Unit tests for the life-cycle of the sdc implementation

### Used javascript-based testing libraries for solidity

- `ethereum-waffle`: Waffle is a Solidity testing library. It allows you to write tests for your contracts with JavaScript.
- `chai`: Chai is an assertion library and provides functions like expect.
- `ethers`: This is a popular Ethereum client library. It allows you to interface with blockchains that implement the Ethereum API.
- `solidity-coverage`: This library gives you coverage reports on unit tests with the help of Istanbul.

### Compile and run tests with hardhat

We provide the essential steps to compile the contracts and run provided unit tests
Check that you have the latest version of npm and node via `npm -version` (should be better than 8.5.0) and `node -v` (should be better than 16.14.2).

1. Check out project
2. Within this folder initialise a new npm project (a basic `package.json` file be created):
```shell
npm i
```
3. Install Hardhat as local solidity dev environment. When prompted select following option: *Create an empty hardhat.config.js*
```shell
npx hardhat init
```
4. Install Hardhat as a development dependency, install further testing dependencies, install open zeppelin contracts.
```shell
npm install --save-dev hardhat
npm install --save-dev @nomiclabs/hardhat-waffle @nomiclabs/hardhat-ethers ethereum-waffle chai  ethers solidity-coverage
npm install @openzeppelin/contracts
```
5. Edit your `hardhat.config.ts` (set version to 0.8.20 and add dependencies):
```
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
};
require("@nomiclabs/hardhat-waffle"); 
require('solidity-coverage');
``` 
7. run `npx hardhat compile`
8. run `npx hardhat test`
9. run `npx hardhat coverage` (optionally)

