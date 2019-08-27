---
eip: 2253
title: wallet_getAddressBook JSON-RPC Method
author: Loredana Cirstea (@loredanacirstea)
discussions-to: https://ethereum-magicians.org/t/eip-2253-add-wallet-getaddressbook-json-rpc-method/3592
status: Draft
type: Standards Track
category: ERC
created: 2019-08-27
requires (*optional): 1474
---

## Simple Summary

This is a proposal for a new JSON-RPC call for retrieving a selection of items from a wallet's address book, with the user's permission.

## Abstract

There is no standardized way for a dApp to request address book information from a user's wallet. This leads to either nonoptimal UX, where the user needs to find and copy-paste an Ethereum address, or to duplication of effort across dApps and decreased privacy.

## Motivation

Address books for wallets are becoming a standard feature, greatly improving usability, while maintaining user ownership on this data.

There is no standardized way for a dApp to leverage this information, with the user's permission. dApps can use the `wallet_getAddressBook` JSON-RPC method to retrieve strictly the information that they need, in order to process the request.

The current proposal will avoid duplication of effort - dApps will not need to ask the user to create another address book with them. And it also protects the user's privacy, while increasing usability.

## Specification

New JSON-RPC method: `wallet_getAddressBook({count, fields})`. Returns a `WalletAddressBookItem[]`
- `count`:
  - optional; when missing, the entire address book is requested.
  - `uint` - how many address book items should be requested.
- `fields`:
  - optional; when missing, all `WalletAddressBookItem` fields are requested.
  - `string[]`
- `WalletAddressBookItem`:
  - `address address` - required
  - `string name` - optional, may not be returned if user refuses

### Examples

**1) A request to return the entire address book, with all fields:**
```
{
  "id":1,
  "jsonrpc": "2.0",
  "method": "wallet_getAddressBook",
  "params": []
}
```
Result:

```
{
  "id":1,
  "jsonrpc": "2.0",
  "result": [
    {
      "address": "0x0000000000000000000000000000000000000001",
      "name": "My Friend"
    },
    {
      "address": "0x0000000000000000000000000000000000000002",
      "name": "Beer Buddy"
    }
  ]
}
```

**2) A request to return one address book item, with all fields:**
```
{
  "id":1,
  "jsonrpc": "2.0",
  "method": "wallet_getAddressBook",
  "params": [
    {
      "count": 1,
    }
  ]
}
```
Result:

```
{
  "id":1,
  "jsonrpc": "2.0",
  "result": [
    {
      "address": "0x0000000000000000000000000000000000000001",
      "name": "My Friend"
    }
  ]
}
```

**3) A request to return three address book items, only containing the address:**
```
{
  "id":1,
  "jsonrpc": "2.0",
  "method": "wallet_getAddressBook",
  "params": [
    {
      "count": 1,
      "fields": ["address"]
    }
  ]
}
```
Result:

```
{
  "id":1,
  "jsonrpc": "2.0",
  "result": [
    {
      "address": "0x0000000000000000000000000000000000000001"
    }
  ]
}
```


### UI Best Practices

The wallet should display a UI to the user, showing the request. The user can accept or reject the request.

If the entire address book is requested, the total number of address book items will be shown. If an address book selection is requested, the user will have to select the items from the address book list.

The wallet will also show radio options for which `WalletAddressBookItem` optional fields the user wants to expose, if those fields were requested.

## Rationale

Copy-pasting Ethereum addresses in dApps is not a good UX. Wallets should and are beginning to implement address books for users.

If all dApps that want to increase their usability will start to implement their own address books, there will be a lot of duplicated effort and lack of privacy for users. The address book data should be controlled by the user and the user should choose how much of this information is given to a dApp.


## Backwards Compatibility

Not relevant, as this is a new method.


## Test Cases

To be done.


## Implementation

To be done.


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
