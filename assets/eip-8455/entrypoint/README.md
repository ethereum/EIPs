# EntryPoint v0.7 bytecode for the regression test

`tests/bogota/eip_reservoir/entrypoint_v07.py` in `execution-specs.patch` holds the runtime bytecode used by `test_entrypoint.py`. It is produced as follows.

```sh
curl -sL https://codeload.github.com/eth-infinitism/account-abstraction/tar.gz/refs/tags/v0.7.0 | tar xz
npm install
node compile.js
```

`compile.js` compiles `contracts/core/EntryPoint.sol` and `contracts/core/SenderCreator.sol` from the tag with solc 0.8.23, optimizer enabled with 1,000,000 runs and `viaIR`, the settings the repository's hardhat config uses for `EntryPoint.sol`, together with `MinimalAccount.sol` from this directory. `compiled.json` then contains the deployed bytecode, the immutable references and the storage layout that the Python module embeds. The EntryPoint's only immutable is the `SenderCreator` address, which the test fills with the address it deploys to; `ReentrancyGuard._status` (slot 2) is set to 1 in the pre-state, as the constructor would.

`MinimalAccount` accepts every user operation and pays the prefund, so no signatures are needed. `Shared` is the contract whose storage slot the two operations create and clear.
