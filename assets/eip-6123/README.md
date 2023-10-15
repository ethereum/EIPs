# SDC Solidity implementation

## Description
The reference SDC implementation can be unit tested with hardhat to understand the trade process logic.

### Compile and run tests with hardhat
We provide the essential steps to compile the contracts and run the provided unit tests.

### Provided Contracts and Tests
- `contracts/ISDC.sol` - Interface contract
- `contracts/SDC.sol` - SDC abstract contract for an OTC Derivative
- `contracts/SDCPledgedBalance.sol` - SDC full implementation for an OTC Derivative
- `contracts/ERC20Settlement.sol` - Mintable settlement token contract for unit tests
- `scripts/SDCTests.js` - Unit tests for the life-cycle of the sdc implementation

### Used javascript-based testing libraries for solidity
- `ethereum-waffle`: Waffle is a Solidity testing library. It allows you to write tests for your contracts with JavaScript.
- `chai`: Chai is an assertion library and provides functions like expect.
- `ethers`: This is a popular Ethereum client library. It allows you to interface with blockchains that implement the Ethereum API.
- `solidity-coverage`: This library gives you coverage reports on unit tests with the help of Istanbul.

### Running the provided Unit Tests

Make sure to run the hardhat node before executing unit tests!

Install dependencies:
```shell
npm i
```

Compile contracts (artefacts and cache will be created):
```shell
npx hardhat compile
```

Run in another terminal to establish a local Ethereum node on localhost (json-rpc server):
```shell
npx hardhat node
```

Go back to the previous terminal to run all tests:
```shell
npx hardhat test
```

Alternatively, run unit tests separately using the script tag:
```shell
npm run test-unit
```

Run to see a list of available custom tasks (besides the default tasks, read-number, write-number, and hello should be available according to tasks/SampleContractTasks.js):
```shell
npx hardhat
```

