# EIP Proposal: Remove SELFDESTRUCT Burn

This is a small follow-up to EIP-6780.

EIP-6780 already removed the more common `SELFDESTRUCT` burn behavior, but it left one last corner case: contracts created in the same transaction can still burn ETH, either by `selfdestruct(self)` or by receiving ETH again later in the same transaction and then getting deleted at finalization.

The problem is that this feature is basically unused, but it still forces special handling in clients, specs, and tests.

I checked mainnet usage with a full replay up to about block 24.95M. The result is:

- **54** pre-Cancun real self-burns,
- **2** post-Cancun real burns through the remaining same-tx path,
- **58** post-Cancun broken-burn attempts, all from one contract, all burning **1 wei**, and all already no-ops under EIP-6780,
- **0** deferred finalization burns.

So the actual remaining burn behavior is extremely rare, and the only notable post-Cancun activity besides the 2 real burns is one contract repeatedly probing the already-broken path.

The idea here is simple: remove the last path where `SELFDESTRUCT` can silently destroy ETH, instead of keeping this odd special case forever.

As a side effect, this also removes the last EVM mechanism by which ETH can leave total supply.
