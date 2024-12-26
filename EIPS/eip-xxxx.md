---
title: Private key deactivation and reactivation
description: Introduce a new precompiled contract to enable Externally Owned Accounts (EOAs) to deactivate and reactivate their private keys.
author: Liyi Guo (@colinlyguo)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2024-12-27
requires: 20, 2612, 7701, 7702
---

## Abstract

This EIP introduces a precompiled contract that enables EOAs with delegated control to smart contracts via [EIP-7702](./eip-7702) to deactivate/reactivate their private keys. This design does not require additional storage fields or account state changes. By leveraging delegated code, reactivation can be performed securely through mechanisms such as social recovery.

## Motivation

[EIP-7702](./eip-7702) enables EOAs to gain smart contract capabilities, but the private key of the EOA still retains full control over the account.

With this EIP, EOAs can fully migrate to smart contract wallets, while retaining recovery options with reactivation. The flexible deactivate/reactivate design also paves the way for native account abstraction. e.g., [EIP-7701](./eip-7701).

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Parameters

| Constant                          | Value                |
|-----------------------------------|----------------------|
| `PRECOMPILE_ADDRESS`              | `0xTBD`              |
| `PRECOMPILE_GAS_COST`             | `5000` (tentative)   |

### Delegated code encoding

The deactivation status is encoded by appending or removing the `0x00` byte at the end of the delegated code. The transitions between two states are as follows:

- Active state: `0xef0100 || address`, the private key is active and can sign transactions.
- Deactivated state: `0xef0100 || address || 0x00`, the private key is deactivated and cannot sign transactions.

### Precompiled contract

A new precompiled contract is introduced at address `PRECOMPILE_ADDRESS`. For each call, it consumes `PRECOMPILE_GAS_COST` gas, and the precompiled contract executes the following steps:
- The precompiled contract checks that the caller is an EOA with delegated code (i.e., its account code begins with the prefix `0xef0100`, as defined in [EIP-7702](./eip-7702)). If the code does not conform to the required prefix, the contract MUST terminate without making any state changes.
- The precompile determines the current state of the delegated code based on its byte length:
    - If the delegated code is 24 bytes (`0xef0100 || address || 0x00`), it removes the last byte (`0x00`), transitioning to the active state (`0xef0100 || address`).
    - If the delegated code is 23 bytes (`0xef0100 || address`), it appends `0x00`, transitioning to the deactivated state (`0xef0100 || address || 0x00`).
- The updated delegated code is saved as the new account code for the EOA.


### Transaction validation
If the account is verified as an EOA with a delegated code (begins with the prefix `0xef0100`), transactions signed by the private key MUST be rejected if the delegated code is in the deactivated state (i.e., `24` bytes long).

### Gas cost
No changes to the base transaction gas cost (`21000`) are required, as the additional valid check for the deactivation status is minimal compared with [EIP-7702](./eip-7702) transactions. Thus it is reasonable to include them in the base gas cost.

## Rationale

### Using a precompiled contract
Alternative methods for implementing this feature include:
- Adding a new transaction type: A new transaction type could deactivate/reactive EOA private keys. This would complicate reactivation, as the contract would need to serve as the authorizer for reactivation, increasing protocol complexity.
- Deploying a regular smart contract: A regular deployed contract could track the `deactivated` status of each `address`. This approach would break the base transaction gas cost of `21000` in transaction validation, as accessing the `deactivated` status would require additional address and storage lookups, increasing gas usage.

### In-protocol reactivation
This approach ensures maximum compatibility with future migrations. EOAs can reactivate their private keys, delegate their accounts to an [EIP-7701](./eip7701) contract, and then deactivate their private keys again. This avoids the limitations of upgradable contracts. e.g., to remove legacy proxy contracts when EOF contracts become available, thereby reducing gas overhead, one can reactivate the EOA and delegate to an EOF proxy contract.

### `5000` Gas `PRECOMPILE_GAS_COST`
The `5000` gas cost is sufficient to cover validation, computation, and storage updates for the delegated code.

### Alternative EOA migration approach
One alternative migration approach involves using a hard fork to edit all existing and new EOAs to upgradable smart contracts using EOA's ECDSA signatures. Users can then upgrade these smart contracts to achieve more granular permission control. However, this approach is incompatible with EOAs that have already delegated to smart contracts, as it overwrites the existing smart contract implementations. The EIP aims to fill this migration gap.

### Avoiding delegated code prefix modification
This EIP appends a byte (`0x00`) to the delegated code instead of modifying the prefix (`0xef0100`) of [EIP-7702](./eip-7702) to ensure forward compatibility. If future prefixes such as `0xef0101` are introduced, changing the prefix (e.g., to `0xef01ff`) makes it unclear which prefix to restore upon reactivation.

### Avoiding account state changes
Another alternative is to add a new field to the account state to store the `deactivated` status. However, this approach complicates the account state. It also brings changes in the account trie structure and RLP encoding used in networking, which complicates the implementation.

### Forwards compatibility for removing EOAs
After all existing and future EOAs have been migrated to smart contracts. It's natural and easy to deprecate this EIP:
- Removing the precompiled contract.
- Removing validation of the deactivation status since all EOAs are smart contracts.
- The appended `0x00` byte can be optionally removed from the delegated code.

## Backwards Compatibility

This EIP maintains backwards compatibility with existing EOAs and contracts.

## Test Cases

```python
# Initialize the state database and precompiled contract
state_db = StateDB()
precompiled_contract = PrecompiledContract()

# Test 1: Valid caller with active state
valid_caller = "0x1234"
delegated_address = bytes.fromhex("112233445566778899aabbccddeeff0011223344")
delegated_code = PrecompiledContract.DELEGATED_CODE_PREFIX + delegated_address
state_db.set_code(valid_caller, delegated_code)  # Active state
assert state_db.get_code(valid_caller) == delegated_code  # Verify initial state

# Toggle to deactivated state
precompiled_contract.run(valid_caller, state_db)
assert state_db.get_code(valid_caller) == delegated_code + b"\x00"  # Verify deactivated

# Toggle back to active state
precompiled_contract.run(valid_caller, state_db)
assert state_db.get_code(valid_caller) == delegated_code  # Verify reactivated

# Test 2: Invalid caller without delegated code
invalid_caller = "0x5678"  # No delegated code
assert state_db.get_code(invalid_caller) == b""  # Verify initial state is empty

# Run contract on invalid caller (should do nothing)
precompiled_contract.run(invalid_caller, state_db)
assert state_db.get_code(invalid_caller) == b""  # State remains unchanged

# Test 3: Caller with invalid prefix
invalid_prefix_caller = "0x9999"
invalid_code = bytes.fromhex("ab01") + delegated_address  # Invalid prefix
state_db.set_code(invalid_prefix_caller, invalid_code)
precompiled_contract.run(invalid_prefix_caller, state_db)
assert state_db.get_code(invalid_prefix_caller) == invalid_code  # State remains unchanged
```

## Reference Implementation

```python
class PrecompiledContract:
    """
    Precompiled contract for toggling the activation status of EOAs
    based on their delegated code.
    """
    DELEGATED_CODE_PREFIX = bytes.fromhex("ef0100")  # Prefix for delegated code
    ACTIVE_CODE_LENGTH = 23  # Length of code in active state
    DEACTIVATED_CODE_LENGTH = 24  # Length of code in deactivated state

    def run(self, caller, state_db):
        """
        Toggles the delegated code of the caller between active and deactivated states.

        Parameters:
        - caller: The address calling the contract.
        - state_db: The state database containing account states.
        """
        # Retrieve the current code of the caller
        code = state_db.get_code(caller)

        # Validate the code prefix
        if not code.startswith(self.DELEGATED_CODE_PREFIX):
            return  # If it's not an EOA with valid delegated code, terminate with no changes

        # Determine the current state based on code length
        if len(code) == self.DEACTIVATED_CODE_LENGTH:  # Deactivated state (ends with 0x00)
            state_db.set_code(caller, code[:-1])  # Remove the last byte to activate
            return
        
        if len(code) == self.ACTIVE_CODE_LENGTH:  # Activated state
            state_db.set_code(caller, code + b"\x00")  # Append 0x00 to deactivate
            return

        # The case should not occur, this is for completeness sake
        return

class StateDB:
    """
    Simplified state database for managing EOA states.
    Other fields (e.g., `nonce`, `codehash`, `balance`, and `storageRoot`) are omitted for simplicity.
    """
    def __init__(self):
        self.accounts = {}

    def get_code(self, addr):
        return self.accounts.get(addr, {}).get("code", b"")

    def set_code(self, addr, value):
        if addr not in self.accounts:
            self.accounts[addr] = {}
        self.accounts[addr]["code"] = value
```

## Security Considerations

### Unchanged gas consumption for transactions
This EIP does not introduce additional gas costs for transactions. The validation of the deactivation status is performed by checking the presence of the appended `0x00` byte in the account's delegated code. This check is computationally lightweight compared to operations like accessing storage.

### Additional status check during transaction validation
The deactivation status is determined by checking the length of the delegated code. This check is computationally trivial and comparable to other account state checks, such as nonce and balance validation. Since it is integrated into the transaction validation process, it does not introduce any significant additional computational overhead.

### Risk of asset freezing
For a malicious wallet, it could deliberately deactivate the account and block reactivation, effectively freezing assets. In this case, the risk is inherent to delegating control and not caused by this protocol.

The risk also exists when the delegated wallet does not support reactivation or implements a flawed reactivation interface, combined with partially functional or non-functional asset transfers. These issues could prevent the user from reactivating the account and result in partial or complete asset freezing. Users can mitigate these risks by using thoroughly audited wallets that fully support this EIP.

### Permit extension for [ERC-20](./eip20)
This EIP does not revoke [ERC-2612](./eip2612) permissions. EOAs supporting this EIP can still authorize transfers by calling the `permit` function of [ERC-20](./eip20) tokens. This issue also exists with [EIP-7702](./eip7702). If wanting to support deactivated EOAs, [ERC-20](./eip20) contracts may need to be upgraded.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
