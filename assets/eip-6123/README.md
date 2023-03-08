# SDC Solidity implementation

## Description
This sdc implementation aims to implement process logic in a very lean way using an integrative solidity implementation and according unit tests

### Provided Contracts and Tests
- `contracts/ISDC.sol` - Interface contract
- `contracts/SDC.sol` - SDC reference implementation contract
- `contracts/SDCToken.sol` - Mintable token contract for unit tests
- `test/SDC.js` - Unit tests for livecycle of sdc implementation 

### Used javascript based testing libraries for solidity
- `ethereum-waffle`: Waffle is a Solidity testing library. It allows you to write tests for your contracts with JavaScript.
- `chai`: Chai is an assertion library and provides functions like expect.
- `ethers`: This is a popular Ethereum client library. It allows you to interface with blockchains that implement the Ethereum API.
- `solidity-coverage`: This library gives you coverage reports on unit tests with the help of Istanbul.

### Compile and run tests with hardhat
We provide the essential steps to compile the contracts and run provided unit tests
Check that you have the latest version of npm and node via `npm -version` (should be better than 8.5.0) and `node -v` (should be better than 16.14.2).

1. Check out project
2. Go to folder and install dependencies: Run `npm i`. The `node_modules` folder should be created
3. run `npx hardhat test`
