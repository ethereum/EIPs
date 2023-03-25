# Reference implementations of ERC-N

## Contract

**ERC-N implementations:**

- [IERC_N.sol](./contracts/IERC_N.sol): interface of `ERC_N`
- [ERC_N.sol](./contracts/ERC_N.sol): a simple and minimal implementation for one-to-one barter type
- [ERC_NMultiBarter.sol](./contracts/extensions/ERC_NMultiBarter.sol): an extensions of `ERC_N.sol` for barter several token belonging to the same contract

**Mocks contracts:**

- [PermissionlessERC_N.sol](./contracts/mocks/PermissionlessERC_N.sol): an exemple of implementation of `ERC_N`
- [PermissionlessERC_NMultiBarter.sol](./contracts/mocks/PermissionlessERC_NMultiBarter.sol): an exemple of implementation of `ERC_NMultiBarter`

_These contract are used in `test`_

## Tests

Tests are writen using [Foundry](https://book.getfoundry.sh/getting-started/installation), here is the list of tests:

- Barter on same contract
- Cannot use an expired signature
- Enable barter on same contract is required
- Nonce prevent signature reuse
- One-to-one barter
- Revert if barters not allowed
- Multi barter
- Cannot barter empty array (multi barter)

## Building instruction

You can build a Foundry repo by running the following scripts:

```
forge init --force
forge install OpenZeppelin/openzeppelin-contract
forge remappings > remappings.txt
rm -r src
rm test/Counter.t.sol
forge build
```

Run tests:

```
forge test -vvvv
```
