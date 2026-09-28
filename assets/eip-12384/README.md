# EIP-12384 token-level reference implementation

The protocol form of EIP-12384 needs a client change. This is the form that ships on any EVM chain today, and the one that has run on Robinhood Chain (chain id 4663) since 2026-09-28.

- `ReferenceFeeERC20.sol`: an ERC-20 that counts its own transfers as references on two ratchets, fast (global, per chain block, first two free, 10 bp·k², capped at 100%) and slow (per originator, per 2048-block window, first free, 2 bp·k², capped at 10%), keyed on the chain's own block (the `ArbSys` precompile on Arbitrum-family chains, since `NUMBER` reports the parent chain there). A transfer pays the larger of the two, in kind, to a settler.
- `NativeSettler.sol`: no owner. Anyone settles a token: what landed is sold for ETH through the token's own market (`IVenue` adapters), half of the ETH goes to the chain's sink, half is wrapped and paid to the stake pool fixed at deployment, which must answer as a pool. Nothing is burned. The settler's own sales are not references.
- `NativeSink.sol`: the chain's half. Ownerless, receive-only. On L1 this role is the EIP's StakeVault, which deposits to the beacon chain; on a rollup it holds.
- `IVenue.sol`: the adapter interface a settler sells through.

Compiles with solc 0.8.26+ against OpenZeppelin 5. Tests, venue adapters, the stake pool and the deployment scripts live with the running deployment.
