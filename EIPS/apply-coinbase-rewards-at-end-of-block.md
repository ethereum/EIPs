---
eip: *
title: Apply Coinbase Rewards At The End Of Block
description: Apply rewards for all transactions to the coinbase at the end of the block.
author: Dragan Rakita (@rakita), Roman Krasiuk (@rkrasiuk)
discussions-to: *
status: Draft
type: Standards Track
category: Core
created: 2023-09-19
---

## Abstract

The transaction fees shall be added to the `COINBASE` balance at the end of the block.

## Motivation

Currently, the transaction fees are applied to the `COINBASE`'s balance at the end of each transaction thus introducing an implicit dependency on each preceding transaction in the block. Moving the transaction reward to the end of the block removes this dependency allowing for various flavors of parallel execution.

## Specification

The sender of the transaction is still credited at the start of the transaction execution and the refund is still issued at the end in order to avoid double-spending. The `COINBASE` reward is accumulated from transaction fees and applied at the end of each block.

```python
def execute_block(block: Block) -> None:
	...
	coinbase_reward = 0

	for tx in block.transactions:
		signer(tx).balance -= tx.fee

		# execute transaction
		...

		signer(tx).balance += refund
		coinbase_reward += tx.fee - refund 

	# apply coinbase reward at the end of the block
	coinbase.balance += coinbase_reward
```

## Rationale

This EIP removes the inherent dependency between transactions within a single block. By aggregating fees and applying them at the end, transactions might be executed in parallel without waiting for the previous ones to complete.

## Backwards Compatibility

Balance is only incremented once at the end of the block and this means that `COINBASE` will not have it incremented within this block.

**Direct Coinbase Payments**

This change does not impact direct payments to `COINBASE`. They can still occur alongside the transaction fees.

**Block Building**

This change will require block builders to accumulate transaction fees when evaluating block value. It does not have a fundamental impact on the profitability of the block.

**Smart Contracts**

The changes to the timing of fee application are only noticeable across transactions. In rare cases, smart contract developers might need to adapt their contracts to account for the possibility of coinbase balance increment occurring at the end of a block.

## Test Cases

**Test Case #1**

```
Sender A Balance Before Block: 1 ETH
Coinbase Balance Before Block: 10 ETH

Transaction #1 from Sender A
Transaction Fee: 0.1 ETH
Sender A Balance After Transaction #1: 0.9 ETH
Coinbase Balance After Transaction #1: 10 ETH

Transaction #2 from Sender A
Transaction Fee: 0.2 ETH 
Sender A Balance After Transaction #2: 0.7 ETH
Coinbase Balance After Transaction #2: 10 ETH

Sender A Balance After Block: 0.7 ETH
Coinbase Balance After Block: 10.3 ETH
```

**Test Case #2**

```
Sender A Balance Before Block: 1 ETH
Coinbase Balance Before Block: 10 ETH

Transaction #1 from Sender A
Transaction Fee: 0.1 ETH
Sender A Balance After Transaction #1: 0.9 ETH
Coinbase Balance After Transaction #1: 10 ETH

Transaction #2 from Sender A
Transaction Fee: 0.2 ETH 
Sender A Balance After Transaction #2: 0.7 ETH
Coinbase Balance After Transaction #2: 10 ETH

Sender A Balance After Block: 0.7 ETH
Coinbase Balance After Block: 10.3 ETH
```

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
