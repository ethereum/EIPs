# EntryPoint v0.7 bytecode for the regression test

`test_entrypoint.py` in `execution-specs.patch` imports the runtime bytecode from `tests/bogota/eip_reservoir/entrypoint_v07.py`. That module is not committed; `reproduce.sh` generates it with `compile.js` when Node.js is available, and skips `test_entrypoint.py` otherwise. To generate it by hand, run from this directory:

```sh
curl -sL https://codeload.github.com/eth-infinitism/account-abstraction/tar.gz/refs/tags/v0.7.0 | tar xz
npm install
node compile.js entrypoint_v07.py
```

and copy `entrypoint_v07.py` into `tests/bogota/eip_reservoir/` of the patched execution specifications.

`compile.js` compiles `contracts/core/EntryPoint.sol` and `contracts/core/SenderCreator.sol` from the tag with solc 0.8.23, optimizer enabled with 1,000,000 runs and `viaIR`, the settings the repository's hardhat config uses for `EntryPoint.sol`, together with `MinimalAccount.sol` from this directory. It writes the deployed bytecode and the immutable references to `entrypoint_v07.py`, and the full compiler output, including the storage layout, to `compiled.json`. The EntryPoint's only immutable is the `SenderCreator` address, which the test fills with the address it deploys to; `ReentrancyGuard._status` (slot 2) is set to 1 in the pre-state, as the constructor would.

`MinimalAccount` accepts every user operation and pays the prefund, so no signatures are needed. `Shared` is the contract whose storage slot the two operations create and clear.
