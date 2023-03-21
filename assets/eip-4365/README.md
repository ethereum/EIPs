# [ERC4365] Redeemable Tokens (Tickets) Reference Implementation

## Core

{{IERC4365}}  
{{ERC4365}}  
{{IERC4365Receiver}}

## Extensions
 
{{ERC4365Expirable}}  
{{ERC4365Payable}}  
{{ERC4365Supply}}  
{{ERC4365URIStorage}}  
{{IERC4365Expirable}}  
{{IERC4365Payable}}  
{{IERC4365Supply}}

## Usage

### Prerequisites

To run this code you first need to install Truffle via npm (node package manager). If you do not already have npm installed,
you can install it [here](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm#using-a-node-version-manager-to-install-nodejs-and-npm).

To install Truffle, run:

```sh
npm install -g truffle
```

If you want to use Ganache to host a personal blockchain, download it [here](https://trufflesuite.com/ganache/).

### Compile

If you want to compile, simply run:

```sh
truffle compile
```

### Test

To run all tests, simply run:

```sh
truffle test
```

You can also run each test individually by calling:

```sh
truffle test {test-location}
```

### Deploy

To deploy the `Ticket.sol` example smart contract, you need to connect to a blockchain. Truffle has a built-in personal blockchain used for testing. Altertently, if you installed 
Ganache, you can use that. 

If you want to use Truffles built-in blockchain, run:

```sh
truffle develop
```

If you want to use Ganache, run:

```sh
truffle deploy
```

However, dont forget to link Ganache to the project (tutorial [here](https://trufflesuite.com/docs/ganache/how-to/link-a-truffle-project/)), alternatively create a Ganache quickstart workspace and match the server host and port in `truffle-config.js`.

## Syntax Highlighting

If you use VSCode, you can enjoy syntax highlighting for your Solidity code ia the [vscode-solidity](https://github.com/juanfranblanco/vscode-solidity) extension. It is also
available via the VSCode extensions marketplace. The recommended approach to set the compiler version is to add the following fields to your VSCode user settings:

```json
{
  "solidity.compileUsingRemoteVersion": "v0.8.4+commit.c7e474f2",
  "solidity.defaultCompiler": "remote"
}
```

Where `v0.8.4+commit.c7e474f2` can be replaced by any other version.

## Todo

- [ ] Add tests

## Credits

- EIP inspirations: [EIP-1155: Multi Token Standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md)
