---
eip: 6366
title: Permission Token
description: A new token that held the permission of an address in an ecosystem
author: Chiro (@chiro-hiro)
discussions-to: https://ethereum-magicians.org/t/eip-644-a-standard-for-permission-token/9105
status: Draft
type: Standards Track
category: ERC
created: 2022-01-19
---

## Abstract

A new token standard that held the permission of an address in an ecosystem. A permission token can be transferred/delegated by the permission owner to an grantee's address.

## Motivation

Special roles like `Owner`, `Operator`, `Manager`, `Validator` are common for many smart contracts because permissioned addresses are used to operate and manage them. It is difficult to audit and maintain these system since these permissions are not managed centrally in a single smart contract.

To secure the communication between smart contracts, this EIP provides a straightforward, centralized, and scalable method for managing permissions.

## Specification

We RECOMMENDED to define permissions are power of 2, that allowed us to create up to `2^256` different roles.

### Notes

- The following specifications use syntax from Solidity `0.8.7` (or above)

### Methods

#### name

Returns the name of the token - e.g. `"OpenPermissionToken"`.

OPTIONAL - This method can be used to improve usability,
but interfaces and other contracts MUST NOT expect these values to be present.

```solidity
function name() external view returns (string memory)
```

#### symbol

Returns the symbol of the token. E.g. `"OPT"`.

OPTIONAL - This method can be used to improve usability,
but interfaces and other contracts MUST NOT expect these values to be present.

```solidity
function symbol() external view returns (string memory)
```

#### permissionOf

Returns the account permission of the given `_owner` address.

```solidity
function permissionOf(address _owner) external view returns (uint256 permission)
```

### permissionRequire

Return `true` if `_required` permission is a subset of `_permission` permission otherwise return `false`.

```solidity
function permissionRequire(uint256 _required, uint256 _permission) external pure returns (bool isPermission);
```

#### transfer

Transfers a subset of `_permission` permission to address `_to`, and MUST emit the `Transfer` event.
The function SHOULD `revert` if the message caller's account permission does not have the subset of the transferring permission. The function SHOULD `revert` if any of transferring permission is existing on target `_to` address.

_Note_ Transfers of `0` permission MUST be treated as normal transfers and emit the `Transfer` event.

```solidity
function transfer(address _to, uint256 _permission) external returns (bool success)
```

#### approve

Allows `_delegatee` to act for the permission owner's behalf, up to the `_permission` permission. If this function is called again it overwrites the current granted with `_permission`.

**Note**:

- `_permission` MUST be a subset of all available permission of permission owner.
- `approve()` method SHOULD `revert` if granting `_permission` permission is not a subset of all available permission of permission owner.

```solidity
function approve(address _delegatee, uint256 _permission) external returns (bool success)
```

#### delegated

Returns the subset permission of the `_owner` address were granted to `_delegatee` address.

```solidity
function delegated(address _owner, address _delegatee) external view returns (uint256 permission)
```

### Events

#### Transfer

MUST trigger when permission are transferred, including zero permission transfers.

A token contract which creates new tokens SHOULD emit a `Transfer` event with the `_from` address set to `address(0x00)` when tokens are created.

```solidity
event Transfer(address indexed _from, address indexed _to, uint256 _value)
```

#### Approval

MUST trigger on any successful call to `approve(address _delegatee, uint256 _permission)`.

```solidity
event Approval(address indexed _owner, address indexed _delegatee, uint256 _permission)
```

## Rationale

Needs discussion.

## Reference Implementation

### Implement

`ERC-644`'s interface in `./IERC644.sol`.

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;

interface IERC644 {
  error AccessDenied(address _owner, address _actor, uint256 _permission);

  error DuplicatedPermission(uint256 _permission);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _delegatee, uint256 _permission);

  function transfer(address _to, uint256 _permission) external returns (bool success);

  function approve(address _delegatee, uint256 _permission) external returns (bool success);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function permissionOf(address _owner) external view returns (uint256 permission);

  function permissionRequire(uint256 _required, uint256 _permission) external pure returns (bool isPermission);

  function delegated(address _owner, address _delegatee) external view returns (uint256 permission);
}
```

Simplest implement of Permission Token

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./IERC644.sol";

contract ERC644 is IERC644 {
  mapping(address => uint256) internal permissions;

  mapping(bytes32 => uint256) internal delegations;

  modifier onlyHasPermission(uint256 _permission) {
    if (permissions[msg.sender] & _permission != _permission) {
      revert AccessDenied(msg.sender, msg.sender, _permission);
    }
    _;
  }

  function transfer(
    address _to,
    uint256 _permission
  ) external override onlyHasPermission(_permission) returns (bool success) {
    address owner = msg.sender;
    // Prevent permission to be burnt
    if (permissions[_to] & _permission > 0) {
      revert DuplicatedPermission(_permission);
    }
    // Clean subset of permission from owner
    permissions[owner] = permissions[owner] ^ _permission;
    // Set subset of permission to new owner
    permissions[_to] = permissions[_to] | _permission;
    emit Transfer(owner, _to, _permission);
    return true;
  }

  function approve(
    address _delegatee,
    uint256 _permission
  ) external override onlyHasPermission(_permission) returns (bool success) {
    address owner = msg.sender;
    delegations[_uniqueKey(owner, _delegatee)] = _permission;
    emit Approval(owner, _delegatee, _permission);
    return true;
  }

  function _uniqueKey(address _owner, address _delegatee) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(_owner, _delegatee));
  }

  function name() external pure override returns (string memory) {
    return 'OpenPermissionToken';
  }

  function symbol() external pure override returns (string memory) {
    return 'OPT';
  }

  function permissionOf(address _owner) external view override returns (uint256 permission) {
    return permissions[_owner];
  }

  function permissionRequire(
    uint256 _required,
    uint256 _permission
  ) external pure override returns (bool isPermission) {
    return _required == _permission & _required;
  }

  function delegated(address _owner, address _delegatee) external view override returns (uint256 permission) {
    // Delegated permission can't be the superset of owner's permission
    return delegations[_uniqueKey(_owner, _delegatee)] & permissions[_owner];
  }
}
```

Example use case:

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;
import "./IERC644.sol";

contract Permissioned {
  error InvalidAddress();

  IERC644 private opt;

  // Define permissions
  uint256 private constant PERMISSION_NONE = 0;
  uint256 private constant PERMISSION_VOTE = 2 ** 0;
  uint256 private constant PERMISSION_EXECUTE = 2 ** 1;
  uint256 private constant PERMISSION_CREATE = 2 ** 2;

  // Define roles
  uint256 private constant ROLE_ADMIN = PERMISSION_VOTE | PERMISSION_EXECUTE | PERMISSION_CREATE;
  uint256 private constant ROLE_OPERATOR = PERMISSION_EXECUTE | PERMISSION_VOTE;

  modifier onlyAllowPermissionOwner(uint256 _required) {
    if (!opt.permissionRequire(_required, opt.permissionOf(msg.sender))) {
      revert IERC644.AccessDenied(msg.sender, msg.sender, _required);
    }
    _;
  }

  modifier onlyAllow(address _owner, uint256 _required) {
    if (_owner == address(0)) {
      revert InvalidAddress();
    }
    // The actor should be the permission owner or delegatee
    if (!opt.permissionRequire(_required, opt.permissionOf(msg.sender) | opt.delegated(_owner, msg.sender))) {
      revert IERC644.AccessDenied(msg.sender, msg.sender, _required);
    }
    _;
  }

  constructor(address _opt) {
    opt = IERC644(_opt);
  }
}

// We could reuse Permissioned contract in many use cases to keep the consistent
contract UseCase is Permissioned {
  function createProposal(address _permissionOwner) external onlyAllow(_permissionOwner, PERMISSION_CREATE) {
    // Only allow actor and delegatee with PERMISSION_CREATE
  }

  function vote() external onlyAllowPermissionOwner(PERMISSION_VOTE) {
    // Only allow permission owner with PERMISSION_VOTE
  }

  function execute() external onlyAllowPermissionOwner(ROLE_OPERATOR) {
    // Only allow permission owner with ROLE_OPERATOR
  }

  function stopProposal() external onlyAllowPermissionOwner(ROLE_ADMIN) {
    // Only allow permission owner with ROLE_ADMIN
  }
}
```

## Security Considerations

Need more discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
