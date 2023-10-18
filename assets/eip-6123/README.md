# SDC Solidity implementation

## Description

The reference SDC implementation can be unit tested with Hardhat to understand the trade process logic.

### Compile and run tests with Hardhat

We provide the essential steps to compile the contracts and run the provided unit tests.

### Provided Contracts and Tests

- `contracts/ISDC.sol` - Interface contract
- `contracts/SDC.sol` - SDC abstract contract for an OTC Derivative
- `contracts/SDCPledgedBalance.sol` - SDC full implementation for an OTC Derivative
- `contracts/IERC20Settlement.sol` - Interface (extending the ERC-20) for settlement tokens used in `SDCPledgedBalance`.
- `contracts/ERC20Settlement.sol` - Mintable settlement token contract implementing `IERC20Settlement` for unit tests
- `test/SDCTests.js` - Unit tests for the life-cycle of the sdc implementation

### Compile and run tests with Hardhat

Install dependencies:
```shell
npm i
```

Run all tests:
```shell
npm test
```

Run all tests with coverage (alternatively):
```shell
npm run coverage
```

### Configuration files

- `package.js` - Javascript package definition.
- `hardhat.config.js` - Hardhat config.

### Used javascript-based testing libraries for solidity

- `ethereum-waffle`: Waffle is a Solidity testing library. It allows you to write tests for your contracts with JavaScript.
- `chai`: Chai is an assertion library and provides functions like expect.
- `ethers`: This is a popular Ethereum client library. It allows you to interface with blockchains that implement the Ethereum API.
- `solidity-coverage`: This library gives you coverage reports on unit tests with the help of Istanbul.
