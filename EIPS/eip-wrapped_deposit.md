---
eip: <to be assigned>
title: Wrapped Deposits
description: A singleton contract for managing asset deposits.
author: Justice Hudson (@jchancehud)
discussions-to: <URL>
status: Draft
type: Informational
created: 2021-12-11
---

## Abstract
The wrapped deposit contract handles deposits of assets (Ether, ERC20, ERC721) on behalf of a user. A user must only approve a spend limit once and then an asset may be deposited to any number of different applications that support deposits from the contract.

## Motivation
The current user flow for depositing assets in dapps is unnecessarily expensive and insecure. To deposit an ERC20 asset a user must either:

  - send an approve transaction for the exact amount being sent, before making a deposit; for every deposit.
  - send an approve transaction for an infinite spend amount before making deposits.

The first option is inconvenient, and expensive. The second option is insecure. Further, explaining approvals to new or non-technical users is confusing. This has to be done in _every_ dapp that supports ERC20 deposits.

## Specification
The wrapped deposit contract SHOULD be deployed at an identifiable address (e.g. `0x1111119a9e30bceadf9f939390293ffacef93fe9`). The contract MUST be non-upgradable with no ability for state variables to be changed.

The wrapped deposit contract MUST have the following public functions:

```js
depositERC20(address to, address token, uint amount) external;
depositERC721(address to, address token, uint tokenId) external;
depositEther(address to) external payable;
```

Each of these functions MUST revert if `to` is an address with a zero code size. Each function MUST attempt to call a method on the `to` address confirming that it is willing and able to accept the deposit. If this function call does not return a true value execution MUST revert. If the asset transfer is not successful execution MUST revert.

The following interfaces SHOULD exist for contracts wishing to accept deposits:

```ts
interface ERC20Receiver {
  function acceptERC20Deposit(address depositor, address token, uint amount) external returns (bool);
}

interface ERC721Receiver {
  function acceptERC721Deposit(address depositor, address token, uint tokenId) external returns (bool);
}

interface EtherReceiver {
  function acceptEtherDeposit(address depositor, uint amount) external returns (bool);
}
```

A receiving contract MAY implement any of these functions as desired. If a given function is not implemented deposits MUST not be sent for that asset type.

## Rationale
Having a single contract that processes all token transfers allows users to submit a single approval per token to deposit to any number of contracts. The user does not have to trust receiving contracts with token spend approvals and receiving contracts have their complexity reduced by not having to implement token transfers themselves.

User experience is improved because a simple global dapp can be implemented with the messaging: "enable token for use in other apps".

## Reference Implementation
https://github.com/jchancehud/wrapped-deposit
```ts
pragma solidity ^0.7.0;

interface ERC20Receiver {
  function acceptERC20Deposit(address depositor, address token, uint amount) external returns (bool);
}

interface ERC721Receiver {
  function acceptERC721Deposit(address depositor, address token, uint tokenid) external returns (bool);
}

interface EtherReceiver {
  function acceptEtherDeposit(address depositor, uint amount) external returns (bool);
}

interface IERC20 {
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

interface IERC721 {
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
}

contract WrappedDeposit {
  function depositERC20(address to, address token, uint amount) public {
    _assertContract(to);
    require(ERC20Receiver(to).acceptERC20Deposit(msg.sender, token, amount));
    bytes memory data = abi.encodeWithSelector(
      IERC20(token).transferFrom.selector,
      msg.sender,
      to,
      amount
    );
    (bool success, bytes memory returndata) = token.call(data);
    require(success);
    // backward compat for tokens incorrectly implementing the transfer function
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), "ERC20 operation did not succeed");
    }
  }

  function depositERC721(address to, address token, uint tokenId) public {
    _assertContract(to);
    require(ERC721Receiver(to).acceptERC721Deposit(msg.sender, token, tokenId));
    IERC721(token).transferFrom(msg.sender, to, tokenId);
  }

  function safeDepositERC721(address to, address token, uint tokenId, bytes memory data) public {
    _assertContract(to);
    require(ERC721Receiver(to).acceptERC721Deposit(msg.sender, token, tokenId));
    IERC721(token).safeTransferFrom(msg.sender, to, tokenId, data);
  }

  function depositEther(address to) public payable {
    _assertContract(to);
    require(EtherReceiver(to).acceptEtherDeposit(msg.sender, msg.value));
    (bool success, ) = to.call{value: msg.value}('');
    require(success, "nonpayable");
  }

  function _assertContract(address c) private view {
    uint size;
    assembly {
      size := extcodesize(c)
    }
    require(size > 0, "noncontract");
  }
}
```
## Security Considerations
The wrapped deposit implementation should be as small as possible to reduce the risk of bugs. The contract should be small enough that an engineer can read and understand it in a few minutes.

Receiving contracts MUST verify that `msg.sender` is equal to the wrapped deposit contract. Failing to do so allows anyone to simulate deposits.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
