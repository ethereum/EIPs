# Diamond-1-Hardhat Implementation

This is a reference implementation for EIP-2535 Diamonds. Other EIP2535 Diamond implementations also exist.

**Note:** The loupe functions in DiamondLoupeFacet.sol MUST be added to a diamond and are required by the EIP-2535 Diamonds standard.

**Note:** In this implementation the loupe functions are NOT gas optimized. The `facets`, `facetFunctionSelectors`, `facetAddresses` loupe functions are not meant to be called on-chain and may use too much gas or run out of gas when called in on-chain transactions. In this implementation these functions should be called by off-chain software like websites and Javascript libraries etc., where gas costs do not matter.


## Installation

1. Install NPM packages:
```console
npm install
```

## Deployment

```console
npx hardhat run scripts/deploy.js
```

### How the scripts/deploy.js script works

The [scripts/deploy.js](scripts/deploy.js) deployment script includes comments to explain how it works.

How a diamond is deployed is not part of the EIP-2535 Diamonds standard. This implementation shows an example. 

## Run tests:
```console
npx hardhat test
```

## Upgrade a diamond

Check the `test/diamondTest.js` file for examples of upgrades.

Note that upgrade functionality is optional. It is possible to deploy a diamond that can't be upgraded, which is a 'Single Cut Diamond'.  It is also possible to deploy an upgradeable diamond and at a later date remove its `diamondCut` function so it can't be upgraded any more.

Note that any number of functions from any number of facets can be added/replaced/removed on a diamond in a single transaction. In addition an initialization function can be executed in the same transaction as an upgrade to initialize any state variables required for an upgrade. This 'everything done in a single transaction' capability ensures a diamond maintains a correct and consistent state during upgrades.

## Facet Information

**Note:** In this implementation the loupe functions are NOT gas optimized. The `facets`, `facetFunctionSelectors`, `facetAddresses` loupe functions are not meant to be called on-chain and may use too much gas or run out of gas when called in on-chain transactions. In this implementation these functions should be called by off-chain software like websites and Javascript libraries etc., where gas costs do not matter as much.

However the `facetAddress` loupe function is gas efficient and can be called in on-chain transactions.

The `contracts/Diamond.sol` file shows an example of implementing a diamond.

The `contracts/facets/DiamondCutFacet.sol` file shows how to implement the `diamondCut` external function.

The `contracts/facets/DiamondLoupeFacet.sol` file shows how to implement the four standard loupe functions.

The `contracts/libraries/LibDiamond.sol` file shows how to implement Diamond Storage and a `diamondCut` internal function.

The `scripts/deploy.js` file shows how to deploy a diamond.

The `test/diamondTest.js` file gives tests for the `diamondCut` function and the Diamond Loupe functions.

## How to Get Started Making Your Diamond

1. Reading and understand [EIP-2535 Diamonds](../../../EIPS/eip-2535.md). If something is unclear let me know!

2. Use a diamond reference implementation. You are at the right place because this is the README for a diamond reference implementation.

This diamond implementation is boilerplate code that makes a diamond compliant with EIP-2535 Diamonds.

Specifically you can copy and use the [DiamondCutFacet.sol](./contracts/facets/DiamondCutFacet.sol) and [DiamondLoupeFacet.sol](./contracts/facets/DiamondLoupeFacet.sol) contracts. They implement the `diamondCut` function and the loupe functions.

The [Diamond.sol](./contracts/Diamond.sol) contract could be used as is, or it could be used as a starting point and customized. This contract is the diamond. Its deployment creates a diamond. It's address is a stable diamond address that does not change.

The [LibDiamond.sol](./contracts/libraries/LibDiamond.sol) library could be used as is. It shows how to implement Diamond Storage. This contract includes contract ownership which you might want to change if you want to implement DAO-based ownership or other form of contract ownership. Go for it. Diamonds can work with any kind of contract ownership strategy. This library contains an internal function version of `diamondCut` that can be used in the constructor of a diamond or other places.

## Calling Diamond Functions

In order to call a function that exists in a diamond you need to use the ABI information of the facet that has the function.

Here is an example that uses web3.js:

```javascript
const myUsefulFacet = new web3.eth.Contract(MyUsefulFacet.abi, diamondAddress);
```

In the code above we create a contract variable so we can call contract functions with it.

In this example we know we will use a diamond because we pass a diamond's address as the second argument. But we are using an ABI from the MyUsefulFacet facet so we can call functions that are defined in that facet. MyUsefulFacet's functions must have been added to the diamond (using diamondCut) in order for the diamond to use the function information provided by the ABI of course.

Here is another example that uses hardhat:

```javascript
const diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
```

Similarly you need to use the ABI of a facet in Solidity code in order to call functions from a diamond. Here's an example of Solidity code that calls a function from a diamond:

```solidity
string result = MyUsefulFacet(address(diamondContract)).getResult()
```

## Author

This example implementation was written by Nick Mudge.

Contact:

- @mudgen
- nick@perfectabstractions.com

## License

CC0-1.0 license. See the license file.
Anyone can use or modify this software for their purposes.

