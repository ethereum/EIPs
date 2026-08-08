---
eip: 8078
title: GETDEPLOYER Opcode
description: A lookup opcode that returns the deployer address of a contract
author: Nolan Wang (@ma1fan)
discussions-to: https://ethereum-magicians.org/t/introduce-sdelegatecall-opcode-for-enhanced-delegatecall-security/23045/
status: Draft
type: Standards Track
category: Core
created: 2025-11-12
---

## Abstract

This EIP introduces a new EVM opcode `GETDEPLOYER` that allows a contract to query the deployer (creator) address of another contract. The lookup is intended to be used in conjunction with existing call opcodes (for example `DELEGATECALL`) so callers can make provenance decisions (whitelists, policy checks) before interacting with external code.

## Motivation

The standard `DELEGATECALL` opcode executes untrusted external code in the context of the calling contract, which has led to numerous security incidents and significant funds loss. For example, the [Bybit hack incident](https://x.com/benbybit/status/1892963530422505586) resulted in a large loss of funds when attackers replaced wallet contract code with backdoored versions.

By providing a way to verify the deployer of the target contract, `GETDEPLOYER` allows developers to implement additional security checks before execution continues, mitigating risks associated with malicious contract replacements or backdoors.

Beyond delegatecall safety, provenance information has broader security utility. Upgradeable smart-contract patterns (proxies, admin-controlled upgrades, and factory-deployed modules) benefit when callers can quickly verify that a newly deployed implementation was created by a trusted deployer before switching or forwarding calls. This reduces reliance on off-chain coordination or event monitoring and allows on-chain policy (for example, deny-by-default until a deployer is verified) to be enforced atomically.

### Additional Uses

- Factory verification: factories that produce many instances can be verified by deployer address rather than checking each instance's code.
- Monitoring and forensics: on-chain tooling can flag changes in deployer provenance as an indicator of potentially suspicious redeploys.
- Lightweight provenance checks: GETDEPLOYER provides a cheaper, semantic lookup complementary to code-hash checks when implementers prefer deployer-level governance.

## Specification

### Overview

To address implementation concerns (stack shape novelty; historical deployer attribution), this proposal introduces a minimal new lookup opcode `GETDEPLOYER`, used in combination with the existing `DELEGATECALL`. The earlier dual-stack-output delegatecall variant has been removed.

### New State Field

Upon contract creation (via `CREATE` or `CREATE2`) at or after the fork activating this EIP, the client MUST persist a new per-account field `deployer` defined as:

- `deployer`: The address in `msg.sender` at the moment the contract is instantiated.

If a contract address is re-created after `SELFDESTRUCT` (possible only with `CREATE2` using the same salt after destruction), the `deployer` field MUST be overwritten with the redeploying contract's (or EOA's) address. Pre-fork contracts MUST return `0x0000000000000000000000000000000000000000` for `deployer` without requiring chain reprocessing.

### Opcode: `GETDEPLOYER`

```text
GETDEPLOYER (0xXX)    // to be assigned
Pop:   addr
Push:  deployer(addr)
```

Semantics:

1. Pops one stack item `addr`.
2. If `addr` is not a contract (no code) pushes `0x0`.
3. If the contract was created before fork activation pushes `0x0`.
4. Otherwise pushes the stored `deployer` field (left padded to 32 bytes as with addresses elsewhere on the stack).

Gas schedule (subject to tuning during ACD process):

- Cold access: 700 (same order as `EXTCODEHASH`/`EXTCODESIZE`).
- Warm access: 100 (align with other warm account reads post EIP-2929).

Touch semantics: Reading `deployer` MUST count as an account access for warm/cold classification but MUST NOT mark the account for deletion protection nor alter `accessed_addresses` beyond normal rules.

### Recommended Pattern

Contracts desiring secure delegate execution perform:

```text
PUSH target          // address of implementation
DUP1                 // keep target for GETDEPLOYER and later DELEGATECALL
GETDEPLOYER          // -> deployer
... (whitelist / verification logic) ...
// if accepted
<prepare gas/args>
DELEGATECALL
```

This preserves the invariant that `DELEGATECALL` only pushes a single stack item (success) and avoids introducing the first net +2 stack opcode.


(Removed) Earlier drafts included a bundled opcode combining delegatecall and deployer lookup. That complexity was dropped; this EIP now scopes strictly to `GETDEPLOYER`.

### CREATE / CREATE2 Hook Pseudocode

```text
onContractCreation(newAddr, creator):
   state[newAddr].deployer = creator
```

### GETDEPLOYER Pseudocode

```text
opcode_GETDEPLOYER():
   addr = pop()
   acct = state[addr]
   if acct.codeLength == 0: push(0); return
   if forkBlockNotReachedAt(acct.creationBlock): push(0); return // pre-fork deployment
   push(acct.deployer)
```

`creationBlock` is implicit (block when account first had non-zero code); clients MAY omit explicit storage of this if they can flag pre-fork contracts by absence of `deployer` field.

### Backward Handling

No chain reprocessing: clients initialize `deployer` only for creations from the activation block onward. Historical addresses simply yield zero, enabling on-chain logic to treat zero as "unknown / legacy". GETDEPLOYER does not change existing call semantics.

### Gas & DoS Considerations

`GETDEPLOYER` uses the same account access tiering as other EXT* opcodes so batching lookups is predictable. It cannot be used to craft new attack vectors beyond those already possible with repeated `EXTCODEHASH`.

### Formal Specification Summary

- New account field: `deployer` (optional presence for pre-fork)
- New opcode: `GETDEPLOYER` (address → deployerAddress|0)
- Recommended contract pattern: `GETDEPLOYER` + checks + `DELEGATECALL`
 
### Example Solidity (Recommended)
 
```solidity
contract SecureProxy {
   mapping(address => bool) public trustedDeployer;
   address public implementation;

   function _verify(address impl) internal view returns (bool) {
      address dep;
      assembly {
         // GETDEPLOYER assumed at opcode 0xXX; subject to assignment
         // For illustration, we use a placeholder Yul verb getdeployer(impl)
         dep := getdeployer(impl)
      }
      if (dep == address(0)) return false; // legacy / unknown
      return trustedDeployer[dep];
   }

   fallback() external payable {
      address impl = implementation;
      require(_verify(impl), "UNTRUSTED_IMPL");
      assembly {
         let ptr := mload(0x40)
         calldatacopy(ptr, 0, calldatasize())
         let success := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
         let size := returndatasize()
         returndatacopy(ptr, 0, size)
         switch success
         case 0 { revert(ptr, size) }
         default { return(ptr, size) }
      }
   }
}
```

### Notes on SELFDESTRUCT / Redeploy

- If an address is destroyed and later re-created (CREATE2 path), its `deployer` MUST reflect the most recent creation, ensuring accurate provenance for current code.
- Historical deployers are intentionally not retained; if required a separate archival indexing proposal would be needed.

### Open Questions for Core Devs

1. Is forward-only tracking acceptable, or is partial backfill (e.g., recent N blocks) desirable?
2. Should we assign a dedicated warm cost distinct from other EXT* opcodes?
3. Do we want to reuse an existing precompile instead of a base opcode to reduce consensus surface?

Feedback will determine parameter tuning (gas costs, warm/cold behavior) but the scope is now fixed to `GETDEPLOYER` only.


## Rationale

The original concept (a single opcode returning both success and deployer) raised two practical concerns:

1. It would be the first opcode to net-add two items to the stack, increasing review complexity and potential for tooling incompatibilities.
2. Historical deployer attribution is not tracked in clients; retroactive reconstruction would require expensive chain-wide recomputation conflicting with future stateless / verkle roadmap efforts.

Separating concerns (lookup vs. call) maintains existing call semantics, minimizes consensus changes, and allows forward-only metadata accrual without reprocessing history. The design mirrors existing provenance-aware patterns (e.g., `EXTCODEHASH` + check) while exposing a more semantically meaningful trust anchor (creator address) than a raw code hash.

Alternative bundled forms were explored and rejected due to subtle behavioral shifts and reduced composability with existing delegatecall abstractions.

Whitelisting deployers is intentionally simple; richer schemes (code hash + deployer, signature verification) can be layered without further protocol changes.

## Backwards Compatibility

Forward-only initialization avoids historical chain scanning. Pre-fork contracts yield `0x0` for `GETDEPLOYER`, enabling callers to distinguish legacy addresses. No existing opcode semantics change.

## Reference Implementation
 
Pseudocode for Geth-like implementation (illustrative only):
 
```go
// During creation
func finalizeCreation(statedb *StateDB, addr common.Address, creator common.Address) {
   acct := statedb.GetOrNewStateObject(addr)
   acct.SetDeployer(creator) // new method
}

// Opcode execution
func opGetDeployer(pc *uint64, evm *EVM, scope *ScopeContext) {
   addrWord := scope.Stack.Pop()
   addr := common.Address(addrWord.Bytes()[12:32])
   so := evm.StateDB.GetStateObject(addr)
   if so == nil || so.CodeSize() == 0 { scope.Stack.Push(U256(0)); return }
   dep := so.Deployer()
   if dep == (common.Address{}) { // pre-fork or unset
      scope.Stack.Push(U256(0)); return
   }
   scope.Stack.Push(AddressToWord(dep))
}
```
 
System tests would validate: creation sets deployer; pre-fork addresses return zero; redeploy after selfdestruct updates deployer.

## Security Considerations

While `GETDEPLOYER` provides an additional security layer compared to relying solely on `DELEGATECALL`, several considerations remain:

1. The deployer address alone may not be sufficient to establish trust, as legitimate deployers could also deploy malicious contracts.

2. Contracts using this opcode should implement proper authorization checks on the returned deployer address.

3. In the case of proxy contracts or contract factories, the deployer might be another contract rather than an EOA, requiring more complex verification.

4. This solution doesn't prevent all types of delegatecall attacks, only those involving unauthorized contract replacements.

5. Developers should consider implementing additional security measures such as:

- Allowlists of trusted deployers
- Contract signature verification
- Code hash verification

Additional considerations introduced by forward-only tracking:

- Attackers may attempt to redeploy (after selfdestruct) with a trusted deployer address via CREATE2 factory impersonation; whitelisting SHOULD validate both deployer and code hash for high-assurance contexts.
- Returning zero for legacy contracts can produce false negatives; callers MUST decide whether to treat `0x0` as deny-by-default or fallback to alternate heuristics.

Recommended mitigations and best practices:

- Combine deployer checks with code-hash or bytecode metadata for high-assurance upgrades: require both deployer ∈ allowlist AND EXTCODEHASH == expected.
- Use multi-signer governance for allowlist updates (on-chain multisig or timelock) rather than single-admin toggles.
- Treat `0x0` as "unknown" and require manual or cross-checked authorization before trusting legacy addresses.
- Monitor for frequent redeploy patterns around the same address and apply stricter policies to those addresses.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
