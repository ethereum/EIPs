---
eip: 2
title: Homestead Hard-fork Changes
author: Vitalik Buterin <v@buterin.com>
status: Final
type: Standards Track
category: Core
created: 2015-11-15
---

### Meta reference

[Homestead](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-606.md).

### Parameters

|   FORK_BLKNUM   | CHAIN_NAME  |
|-----------------|-------------|
|    1,150,000    | Main net    |
|   494,000       | Morden      |
|    0            | Future testnets    |

# Specification

If `block.number >= HOMESTEAD_FORK_BLKNUM`, do the following:

1. The gas cost *for creating contracts via a transaction* is increased from 21,000 to 53,000, i.e. if you send a transaction and the to address is the empty string, the initial gas subtracted is 53,000 plus the gas cost of the tx data, rather than 21,000 as is currently the case. Contract creation from a contract using the `CREATE` opcode is unaffected.
2. All transaction signatures whose s-value is greater than `secp256k1n/2` are now considered invalid. The ECDSA recover precompiled contract remains unchanged and will keep accepting high s-values; this is useful e.g. if a contract recovers old Bitcoin signatures.
3. If contract creation does not have enough gas to pay for the final gas fee for adding the contract code to the state, the contract creation fails (i.e. goes out-of-gas) rather than leaving an empty contract.
4. Change the difficulty adjustment algorithm from the current formula: `block_diff = parent_diff + parent_diff // 2048 * (1 if block_timestamp - parent_timestamp < 13 else -1) + int(2**((block.number // 100000) - 2))` (where the ` + int(2**((block.number // 100000) - 2))` represents the exponential difficulty adjustment component) to `block_diff = parent_diff + parent_diff // 2048 * max(1 - (block_timestamp - parent_timestamp) // 10, -99) + int(2**((block.number // 100000) - 2))`, where `//` is the integer division operator, eg. `6 // 2 = 3`, `7 // 2 = 3`, `8 // 2 = 4`. The `minDifficulty` still defines the minimum difficulty allowed and no adjustment may take it below this.

# Rationale

Currently, there is an excess incentive to create contracts via transactions, where the cost is 21,000, rather than contracts, where the cost is 32,000. Additionally, with the help of suicide refunds, it is currently possible to make a simple ether value transfer using only 11,664 gas; the code for doing this is as follows:

```python
from ethereum import tester as t
> from ethereum import utils
> s = t.state()
> c = s.abi_contract('def init():\n suicide(0x47e25df8822538a8596b28c637896b4d143c351e)', endowment=10**15)
> s.block.get_receipts()[-1].gas_used
11664
> s.block.get_balance(utils.normalize_address(0x47e25df8822538a8596b28c637896b4d143c351e))
1000000000000000
```
This is not a particularly serious problem, but it is nevertheless arguably a bug.

Allowing transactions with any s value with `0 < s < secp256k1n`, as is currently the case, opens a transaction malleability concern, as one can take any transaction, flip the s value from `s` to `secp256k1n - s`, flip the v value (`27 -> 28`, `28 -> 27`), and the resulting signature would still be valid. This is not a serious security flaw, especially since Ethereum uses addresses and not transaction hashes as the input to an ether value transfer or other transaction, but it nevertheless creates a UI inconvenience as an attacker can cause the transaction that gets confirmed in a block to have a different hash from the transaction that any user sends, interfering with user interfaces that use transaction hashes as tracking IDs. Preventing high s values removes this problem.

Making contract creation go out-of-gas if there is not enough gas to pay for the final gas fee has the benefits that:
- (i) it creates a more intuitive "success or fail" distinction in the result of a contract creation process, rather than the current "success, fail, or empty contract" trichotomy;
- (ii) makes failures more easily detectable, as unless contract creation fully succeeds then no contract account will be created at all; and
- (iii) makes contract creation safer in the case where there is an endowment, as there is a guarantee that either the entire initiation process happens or the transaction fails and the endowment is refunded.

The difficulty adjustment change conclusively solves a problem that the Ethereum protocol saw two months ago where an excessive number of miners were mining blocks that contain a timestamp equal to `parent_timestamp + 1`; this skewed the block time distribution, and so the current block time algorithm, which targets a *median* of 13 seconds, continued to target the same median but the mean started increasing. If 51% of miners had started mining blocks in this way, the mean would have increased to infinity. The proposed new formula is roughly based on targeting the mean; one can prove that with the formula in use, an average block time longer than 24 seconds is mathematically impossible in the long term.

The use of `(block_timestamp - parent_timestamp) // 10` as the main input variable rather than the time difference directly serves to maintain the coarse-grained nature of the algorithm, preventing an excessive incentive to set the timestamp difference to exactly 1 in order to create a block that has slightly higher difficulty and that will thus be guaranteed to beat out any possible forks. The cap of -99 simply serves to ensure that the difficulty does not fall extremely far if two blocks happen to be very far apart in time due to a client security bug or other black-swan issue.

# Implementation

This is implemented in Python here:

1. https://github.com/ethereum/pyethereum/blob/d117c8f3fd93359fc641fd850fa799436f7c43b5/ethereum/processblock.py#L130
2. https://github.com/ethereum/pyethereum/blob/d117c8f3fd93359fc641fd850fa799436f7c43b5/ethereum/processblock.py#L129
3. https://github.com/ethereum/pyethereum/blob/d117c8f3fd93359fc641fd850fa799436f7c43b5/ethereum/processblock.py#L304
4. https://github.com/ethereum/pyethereum/blob/d117c8f3fd93359fc641fd850fa799436f7c43b5/ethereum/blocks.py#L42
