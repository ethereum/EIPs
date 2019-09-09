---
eip: TBD
title: Multichain address resolution for ENS
author: Nick Johnson <nick@ens.domains>
type: Standards Track
category: ERC
status: Draft
created: 2019-09-09
---

## Abstract

This EIP introduces the `address` field for ENS resolvers, which permits resolution of addresses for other blockchains via ENS.

## Motivation

With the increasing uptake of ENS by multi-coin wallets, wallet authors have requested the ability to resolve addresses for non-Ethereum chains inside ENS. This specification standardises a way to enter and retrieve these addresses in a cross-client fashion.

## Specification

A new accessor function for resolvers is specified:

```
struct AddressInfo {
    uint coinType;
    bytes addr;
}

function addresses(bytes32 node) external view returns(AddressInfo[] memory);
```

The EIP168 interface ID for this function is 0x699f200f.

When called on a resolver, this function must return a list of cryptocurrency addresses for the specified namehash. Each entry is a struct with two elements, `coinType` and `addr`. An empty list must be returned for an unknown name.

`coinType` is the cryptocurrency coin type index from [SLIP44](https://github.com/satoshilabs/slips/blob/master/slip-0044.md).

`addr` is the cryptocurency address in binary format. For example, the Bitcoin address `1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa` is base58-decoded and stored as the 25 bytes `0x0062e907b15cbf27d5425399ebf6f0fb50ebb88f18c29b7d93`, while the Ethereum address `0x314159265dd8dbb310642f98f50c066173c1259b` is hex-decoded and stored as the 20 bytes `0x314159265dd8dbb310642f98f50c066173c1259b`.

Entries in the returned list need not be in any particular order, and no assumptions should be made by resolving clients about the ordering of entries. Resolvers may change the ordering of entries at will - for example, they may reorder entries for efficiency reasons when an entry is deleted.

The list SHOULD contain at most one entry for each coin type. If more than one entry for a coin type is present in the list, clients may choose any matching entry arbitrarily.

A new event for resolvers is defined:

```
event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);
```

Resolvers MUST emit this event on each change to the list of addresses for a name.

When the address for a given coin type is changed, resolvers MUST emit an event specifying the coin type and the new address. Consumers may assume that this means that the old address for that coin type is no longer contained in the list.

When the address for a given coin type is removed, the event MUST be emitted with `newAddress` set to the empty string.

If a resolver permits overwriting an address of one coin type with an address of another coin type, the resolver MUST emit two events, one deleting the address for the old coin type, and one setting an address for the new coin type.

### Recommended accessor functions

The following functions provide the recommended interface for changing the addresses contained in the address list. Resolvers SHOULD implement this interface for setting addresses unless their needs dictate a different interface.

```
function setAddress(bytes32 node, uint index, uint coinType, bytes calldata addr); function deleteAddress(bytes32 node, uint index) external authorised(node);
```

`setAddress` adds or updates an address in the list at the specified index. If the index is equal to the number of items already in the list, the list is extended and the provided address is set as the new last element. Otherwise, the address replaces the one already at that index.

The contract will revert if the caller attempts to replace an address of one coin type with an address of another; instead, callers should first call `deleteAddress` on the old address, followed by `setAddress` with the new one.

The contract will revert if the supplied index is greater than the number of items in the list.

This function emits an `AddressChanged` event with the new address.

`deleteAddress` removes the address at the specified index from the list of addresses. This is accomplished as follows:

 1. If the `index` is not the last element of the list, the address from the end of the list is copied into the element specified by `index`.
 2. The list is shortened by one element.

This process removes elements from the list in constant-time, but results in reordering the list.

The contract will revert if `index` is greater than or equal to the number of elements in the list.

This function emits an `AddressChanged` event with the coin ID of the address at the provided index and an empty byte string for the address.

### Example

An example implementation of a resolver that supports this EIP is provided here:

```
contract AddressResolver is ResolverBase {
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    struct AddressInfo {
        uint coinType;
        bytes addr;
    }

    mapping(bytes32=>AddressInfo[]) _addresses;

    function setAddress(bytes32 node, uint index, uint coinType, bytes calldata addr) external authorised(node) {
        AddressInfo[] storage addrs = _addresses[node];
        if(index == addrs.length) {
            addrs.push(AddressInfo(coinType, addr));
        } else {
            require(addrs[index].coinType == coinType);
            addrs[index].addr = addr;
        }
        emit AddressChanged(node, coinType, addr);
    }

    function deleteAddress(bytes32 node, uint index) external authorised(node) {
        AddressInfo[] storage addrs = _addresses[node];
        emit AddressChanged(node, addrs[index].coinType, "");
        if(index < addrs.length - 1) {
            addrs[index] = addrs[addrs.length - 1];
        }
        addrs.length--;
    }

    function addresses(bytes32 node) external view returns(AddressInfo[] memory) {
        return _addresses[node];
    }

    function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
        return interfaceID == this.addresses.selector || super.supportsInterface(interfaceID);
    }
}
```

### Implementation

Implementation TBD

## Backwards Compatibility

For backwards compatibility with the `addr(bytes32)` interface, and to minimise the number of function calls required by clients, we recommend that resolvers implement the following additional behaviour:

 - When `addresses` is called, check if the `addr` field is set. If it is, append an item to the returned list with the coin ID for Ether (60) and the address stored in the `addr` field.
 - When `setAddress` is called with the coin ID for Ether, call `setAddr` with the provided address, instead of adding it to the list. The `AddressChanged` event should still be emitted.
 - When `deleteAddress` is called with an index equal to the length of the list, and the `addr` field is not set to 0, call `setAddr` with 0 instead of deleting the specified item from the list. The `AddressChanged` event should still be emitted.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
