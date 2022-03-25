# Reference Implementation of the proposed Royalty Bearing NFT Smart Contract Standard from Treetrunk.io

## Abstract
The proposal directly connects NFTs and royalties in a smart contract architecture extending the ERC721 standard, with the aim of precluding central authorities from manipulating or circumventing payments to those who are legally entitled to them.

The proposal builds upon the [OpenZeppelin Smart Contract Toolbox](https://github.com/OpenZeppelin/openzeppelin-contracts) architecture, and extends it to include royalty account management (CRUD), royalty balance and payments management, simple trading capabilities -- Listing/Unlisting/Buying -- and capabilities to trace trading on exchanges. The royalty management capabilities allow for hierarchical royalty structures, referred to herein as royalty trees, to be established by logically connecting a "parent" NFT to its "children", and recursively enabling NFT "children" to have more children. 

## Motivation
The management of royalties is an age-old problem characterized by complex contracts, opaque management, plenty of cheating and fraud. 

The above is especially true for a hierarchy of royalties, where one or more assets is derived from an original asset such as a print from an original painting, or a song is used in the creation of another song, or distribution rights and compensation are managed through a series of affiliates. 

In the example below, the artist who created the original is eligible to receive proceeds from every sale, and resale, of a print. 

![Fig1](https://i.imgur.com/Py6bYQw.png)


The basic concept for hierarchical royalties utilizing the above "ancestry concept" is demonstrated in the figure below.

![Fig2](https://i.imgur.com/7MtWzBV.png)


In order to solve for the complicated inheritance problem, this proposal breaks down the recursive problem of the hierarchy tree of depth N into N separate problems, one for each layer. This allows us to traverse the tree from its lowest level upwards to its root most efficiently.

This affords creators, and the distributors of art derived from the original, the opportunity to achieve passive income from the creative process, enhancing the value of an NFT, since it now not only has intrinsic value but also comes with an attached cash flow.

## Specification Outline

This proposal introduces several new concepts as extensions to the ERC721 standard:
* **Royalty Account (RA)**
    * A Royalty Account is attached to each NFT through its `tokenId` and consists of several sub-accounts which can be accounts of individuals or other RAs. A Royalty Account is identified by an account identifier.
* **Account Type**
    * This specifies if an RA Sub Account belongs to an individual (user) or is another RA. If there is another RA as an RA Sub Account, the allocated balance needs to be reallocated to the Sub Accounts making up the referenced RA.
* **Royalty Split**
    * The percentage each Sub Account receives based on a sale of an NFT that is associated with an RA
* **Royalty Balance**
    * The royalty balance associated with an RA
* **Sub Account Royalty Balance**
    * The royalty balance associated to each RA Sub Account. Note that only individual accounts can carry a balance that can be paid out. That means that if an RA Sub Account is an RA, its final Sub Account balance must be zero, since all RA balances must be allocated to individual accounts. 
* **Token Type**
    * Token Type is given as either ETH or the symbol of the supported ERC 20/223/777 tokens such as `DAI`
* **Asset ID**
    * This is the `tokenId` the RA belongs to.
* **Parent**
    * This indicates which `tokenId` is the immediate parent of the `tokenId` to which an RA belongs.

### Data Structures

In order to create an interconnected data structure linking NFTs to RAs that is search optimized requires the following additions to the global data structures of an ERC721:

* Adding structs for a Royalty Account and associated Royalty Sub Accounts to establish the concept of a Royalty Account with sub accounts.
* Defining an `raAccountId` as the keccak256 hash of `tokenId`, the actual `owner` address, and the current block number, `block.blocknumber`
* Mapping a `tokenId` to an `raAccountID` in order to connect an RA `raAccountId` to a `tokenId`
* Mapping the `raAccountID` to a `RoyaltyAccount` in order to connect the account identifier to the actual account.
* An `ancestry` mapping of the parent-to-child NFT relationship
* A mapping of supported token types to their origin contracts and last validated balance (for trading and royalty payment purposes)
* A mapping with a struct for a registered payment to be made in the `executePayment` function and validated in `safeTransferFrom`. This is sufficient, because a payment once received and distributed in the `safeTransferFrom` function will be removed from the mapping.
* A mapping for listing NFTs to be sold

### Royalty Account Functions

Definitions and interfaces for the Royalty Account RUD (Read-Update-Delete) functions. Because the RA is created in the minting function, there is no need to have a function to create a royalty account separately.

### Minting of a royalty bearing NFT

When an NFT is minted, an RA must be created and associated with the NFT and the NFT owner, and, if there is an ancestor, with the ancestor's RA. To this end the specification utilizes the `_safemint` function in a newly defined `mint` function and applies various business rules on the input variables.

### Listing NFTs for Sale and removing a listing

Authorized user addresses can list NFTs for sale for non-exchange mediated NFT purchases.

### Payment Function from Buyer to Seller

To avoid royalty circumvention, a buyer will always pay the NFT contract directly and not the seller. The seller is paid through the royalty distribution and can later request a payout.

The payment process depends on whether the payment is received in ETH or an ERC 20 token:
* ERC 20 Token
    1. The Buyer must `approve` the NFT contract for the purchase price, `payment` for the selected payment token (ERC20 contract address).
    2. For an ERC20 payment token, the Buyer must then call the `executePayment` in the NFT contract -- the ERC20 is not directly involved.
* For a non-ERC20 payment, the Buyer must send a protocol token (ETH) to the NFT contract, and is required to send `msg.data` encoded as an array of purchased NFTs `uint256[] tokenId`.

### Modified NFT Transfer function including required Trade data to allocate royalties

The input parameters must satisfy several requirements for the NFT to be transferred AFTER the royalties have been properly distributed. Furthermore, the ability to transfer more than one token at a time is also considered.

The proposal defines:
* Input parameter validation
* Payment Parameter Validation
* Distributing Royalties
* Update RA ownership with payout
* Transferring Ownership of the NFT 
* Removing the Payment entry in `registeredPayment` after successful transfer

##### Distributing Royalties

The approach to distributing royalties is to break down the hierarchical structure of interconnected RAs into layers and then process one layer at time, where each relationship between a token and its ancestor is utilized to traverse the RA chain until the root ancestor and associated RA is reached.

### Paying out Royalties to the NFT owner -- `from` address in `safeTransferFrom` function

This is the final part of the proposal.

There are two versions of the payout function -- a `public` function and an `internal` function.

The public function has the following interface:
```
function royaltyPayOut (uint256 tokenId, address _RAsubaccount, address payable _payoutaccount, payable uint256 _amount) public virtual nonReentrant returns (bool)
```

where we only need the `tokenId`, the RA Sub Account address, `_RAsubaccount` which is the `owner`, and the amount to be paid out, `_amount`. Note that the function has [`nonReentrant` modifier protection](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol), because funds are being payed out.

#### Sending a Payout Payment

The following steps need to be taken:
* find the RA Sub Account based on `RAaccount` and the `subaccountPos` and extract the balance
* extract `tokentype` from the Sub Account
* based on the token type, send the payout payment (not exceeding the available balance)

## Installation & Tests

Follow the steps below to run the smart contracts test and generate coverage reports:

- Fork this repo
- [Install NodeJS](https://nodejs.org/en/download/)
- [Install a NodeJS Lite Server](https://www.npmjs.com/package/lite-server)
- [Install Truffle](https://trufflesuite.com/docs/truffle/getting-started/installation.html)
- [Install Truffle Assertions Library](https://www.npmjs.com/package/truffle-assertions)
- [Install Truffle Contract Size Library](https://www.npmjs.com/package/truffle-contract-size)
- [Select & Install an Ethereum client of your choice for local testing only](https://trufflesuite.com/docs/truffle/reference/choosing-an-ethereum-client)
- [Install Prettier](https://www.npmjs.com/package/prettier) and its [Solidity Plugin](https://www.npmjs.com/package/prettier-plugin-solidity)
- [Install Solidity Test Coverage](https://www.npmjs.com/package/solidity-coverage)
- [Install the Eth Gas Reporter](https://www.npmjs.com/package/eth-gas-reporter) 
- [Install the Open Zeppelin Contract Module](https://www.npmjs.com/package/@openzeppelin/contracts)
- [Install the ABDK Numerical Solidity Libraries](https://www.npmjs.com/package/abdk-libraries-solidity)
- Run Migrations
- Run the Truffle tests in the different test folders

Note that we are pointing to the Polygon Mumbai Test network in `truffle-config.js`. Please, adjust this if you want a different network.

### Coverage Report
To generate a coverage report, this command needs to be executed:
```sh
truffle run coverage
```
The generated HTML report can be found in the `/coverage` folder.

### Smart Contracts Test
The following commands should be performed to run a specific test:
```sh
truffle test test/transferByERC20_trxntype_0.test.js
```
or to run a group of tests:
```sh
truffle test test/transfer*
```

## Security Testing

The MythX Pro deep analysis security reports of the contracts can be found [here](https://github.com/treetrunkio/treetrunk-nft-reference-implementation/blob/main/docs).

## Licensing

This repo is licensed under [Apache 2.0](https://github.com/treetrunkio/treetrunk-nft-reference-implementation/blob/main/LICENSE).

## Authors
- Andreas Freund (@Therecanbeonlyone1969)
- Alexander Pyatakov (@Pyatakov)
- Volodymyr Shvets (@vshvets-bc)

## Contact

andreas.freund@treetrunk.io