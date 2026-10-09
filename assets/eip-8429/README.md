# EIP-8429 token-level reference implementation

The protocol form of EIP-8429 needs a client change. This is the form that ships on any EVM chain today, and the one that has run on Robinhood Chain (chain id 4663) since 2026-09-28.

- `ReferenceFeeERC20.sol`: an ERC-20 that counts its own transfers as references on two ratchets, fast (global, per chain block, first two free, 10 bp·k², capped at 100%) and slow (per originator, per 2048-block window, first free, 2 bp·k², capped at 10%), keyed on the chain's own block (the `ArbSys` precompile on Arbitrum-family chains, since `NUMBER` reports the parent chain there). A transfer pays the larger of the two, in kind, to a settler.
- `NativeSettler.sol`: no owner. Anyone settles a token: what landed is sold for ETH through the token's own market (`IVenue` adapters), half of the ETH goes to the chain's sink, half is wrapped and paid to the stake pool fixed at deployment, which must answer as a pool. Nothing is burned. The settler's own sales are not references.
- `NativeSink.sol`: the chain's half. Ownerless, receive-only. On L1 this role is the EIP's StakeVault, which deposits to the beacon chain; on a rollup it holds.
- `IVenue.sol`: the adapter interface a settler sells through.

Compiles with solc 0.8.26+ against OpenZeppelin 5. Tests, venue adapters, the stake pool and the deployment scripts live with the running deployment.


## Naming

This draft was opened under the provisional number 12384 and the contracts deployed on Robinhood Chain were compiled with the interface named `IERC12384`. The editors assigned 8429. The sources here are the deployed sources with that one identifier renamed to `IERC8429`; the ABI and the interface id are unchanged.

## Stake vault

`StakeVault.sol` is the vault the protocol form pays into, and what `NativeSink` stands in for on a chain with no validator set. It never creates a validator: an operator does, and the vault tops up one it has proven, through EIP-4788, to carry its withdrawal credentials. Tests, the mainnet proof fixture and the script that produced it are at https://github.com/staccDOTsol/squarefun (`test/StakeVault.t.sol`, `test/StakeVaultMainnetProof.t.sol`, `script/beacon/prove.py`).
