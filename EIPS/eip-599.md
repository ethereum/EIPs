## Preamble

    EIP: <to be assigned>
    Title: 'Valid until block' field for transactions
    Author: Nick Johnson <nick@ethereum.org>, Konrad Feldmeier <konrad@brainbot.com>
    Type: Standard Track
    Category Core
    Status: Draft
    Created: 2017-04-10


## Simple Summary
This EIP adds a new field to transactions, `valid_until_block`. Transactions containing this field may only be included in blocks with numbers less than or equal to the value in this field.

## Motivation
Presently, transaction eviction is a significant problem for nodes; if a node's transaction pool fills up, resulting in the eviction of a transaction, it may receive the same transaction from another node immediately afterwards. Without tracking evicted transactions, nodes cannot determine that they've seen the transaction before, and if they do track evicted transactions, an attacker can compel them to waste space keeping track of them. The result of this is that even legitimate transactions may stick around in a busy pool indefinitely, while an attacker can deliberately seek to bloat the network's transaction pools.

Further, in cases where the network is busy, or a transaction is published with a low gas price, or with a nonce gap or other problem that prevents it from being mined immediately, the transaction may be executed at any time in the future. This can cause trouble for users, where an effect can take place much later than intended, with no clean way to cancel it.

This proposal addresses both of these issues by allowing nodes to place a hard limit on how long they will retain and propagate transactions, limiting the impact of transaction pool bloat and allowing smarter eviction strategies, while also providing users with a way to submit transactions that self-destruct if not mined within a fixed time period.

## Specification
The following names are used throughout this specification:

 - `valid_until_block` - The block number after which a transaction may no longer be included in the chain.
 - `current_blocknumber` - The number of the current block.
 - `transaction_ttl` - The maximum number of blocks in the future a transaction's `valid_until_block` field may be, in order to be accepted and relayed by a given node.
 - `fork_blocknumber` - The block number at which this change becomes active.

Transactions are RLP-encoded lists described in the whitepaper as containing the 9 elements `(T_n, T_p, T_g, T_t, T_v, T_d, T_w, T_r, T_s)`, or `(T_n, T_p, T_g, T_t, T_v, T_i, T_w, T_r, T_s)` for contract-creation transactions. This EIP adds the field `T_b` as a tenth element to both tuples. `T_b` is defined as the latest block number at which this transaction may be included in the chain, and is hereafter referred to equivalently as `valid_until_block`.

Block validation rules are amended to state that a block is invalid if it contains a 10-element transaction whose `T_b` is less than the block's number.

Nodes MUST accept both 9-element and valid 10-element transactions in mined blocks.

Nodes should not relay transactions whose `valid_until_block` is in the past, as these transactions are un-mineable. Nodes should treat other nodes that relay such transactions to them as broken or malicious.

Nodes are also encouraged to set a transaction TTL, and refuse to accept or relay transactions where `valid_until_block > current_blocknumber + transaction_ttl`. As an implementation guideline, we suggest a default transaction TTL of 6000 - approximately one day.

In regards to transaction pool inclusion and relaying, nodes are further encouraged to treat 9-element transactions as having a `valid_until_block` value of `fork_blocknumber + transaction_ttl`.

The standard JSON APIs accepting transaction parameters are amended to add a parameter `valid_until_block`. If not specified, it should default to `current_blocknumber + transaction_ttl`.

## Rationale
The concerns described in the motivation section presupposed some way to determine when a transaction was created. However, storing a creation timestamp or block number in a transaction would require enforcing a TTL by consensus, and provides no mechanism by which a user can adjust the expiry time to something more suitable for their use-case. In contrast, specifying the last block at which a transaction may validly be mined both provides users with a way to set a transaction's TTL, and allows individual nodes to judge what TTLs they will accept on incoming transactions.

With this system, there is no need for a global restriction on the maximum allowable TTL; nodes will set it based on their own needs in order to preserve the usefulness of the network for themselves. Combined with the expiry of the `valid_until_block` value, this allows nodes to evict old transactions and know they will not be relayed back to them, as well as refusing to accept transactions with an excessive TTL.

## Backwards Compatibility
Existing transactions remain valid if included in blocks by miners, but the recommended propagation strategy means that these will quickly cease being relayed by standard nodes. This ensures that there is no need to reissue existing transactions en-masse during the transition period, while also preventing legacy transactions from staying indefinitely.

In order to ensure effective propagation, all existing code that generates or processes transactions will need to be updated to handle transactions with a `valid_until_block` field.

## Test Cases
TBD

## Implementation
TBD

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
