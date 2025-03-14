# Withdrawal requests fee analysis

Analysis of the following parameters of the Withdrawal request smart contract:
* `MAX_WITHDRAWAL_REQUESTS_PER_BLOCK = 16`
* `TARGET_WITHDRAWAL_REQUESTS_PER_BLOCK = 2`

**TL; DR:** These parameters have reasonable values.

## Consensus layer with TARGET=2, MAX=16

Full withdrawal requests doesn't create additional data complexity on the CL side as the changes are applied to the list of validators.

Current exit churn size allows to initiate withdrawal for 256 ETH per epoch, if a number of request per epoch is at its level (`32 * MAX = 512` requests) then the average withdrawing amount should be no bigger than `0.5 ETH` to fit the churn. It is not unreasonable to assume that most of the time this limit will be satisfied.

Partial withdrawals has a separate list which processing depends on the exit churn. If there is enough churn then pending partial withdrawal request will be processed at least `MIN_VALIDATOR_WITHDRAWABILITY_DELAY = 256` epochs after it was queued on the CL. This delay sets a lower boundary on the number of pending withdrawals in the queue in a situation when each block has `MAX=16` requests, it is `256 * 32 * 16 = 131,072`, which is `3 MB` of data. In an extreme case scenario when e.g. ~10% of validators are exiting this number can grow up to `192 MB`.

With `TARGET=2` requests per each block the above numbers are reduced to `0.375 MB` and `24 MB` respectively. Average amount for a partial withdrawal increases up to `4.0 ETH`.

## Attack via prohibitive fee

Full withdrawal requests are a security mechanism and an attacker can potentially benefit from block this functionality by keep the request fee at a prohibitive level. This section explores such attack with more details.

The cost of attack includes two parts. First part is to raise the fee to a certain level (the base cost) and the second part is to keep the fee at that level (per block cost).

The fee is updated at the end of the block processing, so it remains the same regardless of a number of requests submitted within one block. The lowest fee is `1 Wei` which makes the base cost of this attack near to `0`. The cost per block is computed as `prohibitive_fee * TARGET`.

There are two ways to increase the cost:
* Raise fee upon each request -- affects mostly the base cost, has a slight effect on the cost per block
* Increase `TARGET` -- affects the cost per block

The cost of attack with the status quo and above improvements are provided in the table below. The second cost is the cost per hour of such attack, i.e. cost per block times `300` (number of slots per hour).

| Fee | TARGET=2 | TARGET=2 + fine-grained fee | TARGET=8 |
|-|-|-|-|
| 0.0001 ETH | 0.06 ETH | 0.07 ETH | 0.25 ETH |
| 0.01 ETH   | 6.25 ETH | 6.61 ETH | 25.00 ETH |
| 0.1 ETH    | 61.98 ETH | 65.56 ETH | 247.92 ETH |
| 0.5 ETH    | 303.39 ETH | 320.93 ETH | 1213.58 ETH |
| 1 ETH      | 614.59 ETH |  650.10 ETH | 2458.37 ETH |
| 2 ETH      | 1244.95 ETH | 1316.90 ETH | 4979.79 ETH |
| 4 ETH      | 2521.76 ETH | 2667.53 ETH | 10087.02 ETH |

To summarize:
* raising fee upon each requests increases the cost of an hour of attack by _~6%_, while `TARGET=8` makes the 4 times increase
* with the status quo the attack is not sustainable long term

## UX

Assuming `1 Gwei` to be a reasonable fee per request, it will take 2.75 hours for the fee to reach this level if someone submits 2,000 requests in one block (the max possible number to fit in 30M gas block).

From the UX standpoint it might seem quite long, but `TARGET=2`, comparing to e.g. `TARGET=8`, reduces the strain on the protocol by more efficiently rate limiting the growth of the EL and CL queues.
