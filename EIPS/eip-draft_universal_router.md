---
eip: <to be assigned>
title: Universal Router Contract
description: Universal router contract designed for token allowance that eliminates all `approve` transactions in the future.
author: Zergity <zergity@gmail.com>
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2022-12-12
requires: EIP20, EIP721, EIP1155
---

## Abstract

A universal router contract that executes transactions with the following steps:
  * (optional) call a calculation contract to get the `amountIn` value, and ensure that this `amountIn` is not greater than an input `amountInMax`
  * transfer `amountIn` of a token from `msg.sender` to a `recipient` address
  * call a contract function to execute an action
  * (optional) verify the returning amount of a token must be no less than an input `amountOutMin`

## Motivation

Most Dapp router contracts have the following pattern: approve/permit, (optional) calculation, transferFrom, action, and (optionally) verify the token output. This requires `n*m*k` `allow` (or `permit`) transactions, for `n` Dapps, `m` tokens and `k` user addresses. Even though user approves a contract to spend their tokens, it's the front-end code that they trust, not the contract itself. Anyone can create a front-end code and trick the users to sign a transaction to interact with the Uniswap Router contract and steal all their tokens that have been approved.

Universal Router separates token allowance logic from application logic, acts as a manifest for users when signing a transaction. It saves `(n-1)*m*k` approval transactions for old tokens and **ALL** approval transactions for new tokens. The Universal Router contract is designed to be simple and easy to verify and audit. It's counter-factually `CREATE2`'ed so any new token contracts can hardcode and skip the allowance check entirely.

## Specification

```
struct Action {
    bool output;    // true for output action, false for input action
    uint eip;       // token type: 0 for ETH, # for ERC#
    address token;  // token contract address
    uint id;        // token id for ERC-721 and ERC-1155
    uint amount;    // amountInMax for input action, amountOutMin for output action
    address recipient;
    address code;   // contract address
    bytes data;     // contract data
}
```

```
interface IUniversalRouter {
    function exec(Action[] calldata actions) external payable returns (uint[] memory results);
}
```

Universal Router contract is counter-factually `CREATE2`'ed at address \<TBD\> across all EVM-compatible networks.

### Input Action
Actions with `action.output == false` declare which and how many tokens are transferred from `msg.sender` to `action.recipient`.
1. If the `action.code` address is not `0x0`, the `amountIn` is returned by the contract call `action.code.call(action.data)`. This contract function must return a single `uint256` value. If this `amountIn` is greater than `action.amount`, reverts with "EXCESSIVE_INPUT_AMOUNT". If the `action.code` is `0x0`, `amountIn` is set to `action.amount`.
2. `action.eip` specifies the token standard, or `ETH` if it's `0`. If the token is `ETH` and the `recipient` is `0x0`, step #3 is skipped and no transfer is taken, the `amountIn` will be passed to the next output action as the transaction value.
3. Transfer `amountIn` of tokens from `msg.sender` to `action.recipient`.

### Output Action
Actions with `action.output == true` declare the main application action to call, and optionally verify the output token after all is done.
1. If the `action.amount` is not zero, the current token balance of `action.recipient` is recorded for later comparison.
2. Execute the `action.code.call{value: value}(action.data)`, where `value` can be zero or the `amountIn` of the last `ETH` input with an empty `recipient` (see Input Action #2).

### Output Token Verification
After all the actions are handled as above, every token balance tracked in Output Action #2 is queried again for comparison. The balance change must not be less than `action.amount` of each output action, otherwise reverts with "INSUFFICIENT_OUTPUT_AMOUNT".

### Usage Samples
#### UniswapRouter.swapExactTokensForTokens
```
// legacy function
UniswapV2Router01.swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
)

// this function does what UniswapV2Router01.swapExactTokensForTokens does, without the token transferFrom part
UniswapV2Helper01.swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
)

// this transaction is signed by user to execute the swap instead of the legacy function
UniversalRouter.exec([{
    output: false,
    eip: 20,
    token: path[0],
    id: 0,
    amount: amountIn,
    recipient: UniswapV2Library.pairFor(factory, path[0], path[1]),
    code: address(0x0),
    data: "",
}, {
    output: true,
    eip: 20,
    token: path[path.length-1],
    id: 0,
    amount: amountOutMin,
    recipient: to,
    code: UniswapV2Helper01.address,
    data: iface.encodeFunctionData("swapExactTokensForTokens", [amountIn, amountOutMin, path, to, deadline]),
}])
```
#### UniswapRouter.swapTokensForExactTokens
```
// legacy function
UniswapV2Router01.swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
)

// this function does what UniswapV2Router01.swapTokensForExactTokens does, without the token transferFrom part
UniswapV2Helper01.swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
)

// this function extract only the first amountIn of UniswapV2Library.getAmountsIn
UniswapV2Helper01.getAmountIn(uint amountOut, address[] memory path) returns (uint amountIn) {
    return UniswapV2Library.getAmountsIn(factory, amountOut, path)[0];
}

// this transaction is signed by user to execute the swap instead of the legacy function
UniversalRouter.exec([{
    output: false,
    eip: 20,
    token: path[0],
    id: 0,
    amount: amountInMax,
    recipient: UniswapV2Library.pairFor(factory, path[0], path[1]),
    code: UniswapV2Helper01.address,
    data: encodeFunctionData("getAmountIn", [amountOut, path]),
}, {
    output: true,
    eip: 20,
    token: path[path.length-1],
    id: 0,
    amount: amountOut,
    recipient: to,
    code: UniswapV2Helper01.address,
    data: encodeFunctionData("swapTokensForExactTokens", [amountOut, amountInMax, path, to, deadline]),
}])
```

## Rationale

The `Permit` type signature is not supported since the purpose of Universal Router is to eliminate all `approve` signatures for new tokens, and *most* for old tokens.

Flashloan transactions are out of scope since it requires support from the application contracts themself.

## Backwards Compatibility

Old token contracts (ERC20, ERC721 and ERC1155) require approval for Universal Router once for each account.

New token contracts can pre-configure the Universal Router as a trusted spender, and no approval transaction is required.

## Test Cases

Test cases for an implementation are mandatory for EIPs that are affecting consensus changes.  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Reference Implementation

```
contract UniversalRouter is IUniversalRouter {
    function exec(
        Action[] calldata actions
    ) override external payable returns (uint[] memory results) {
        results = new uint[](actions.length);
        uint value;
        for (uint i = 0; i < actions.length; ++i) {
            Action memory action = actions[i];
            if (!action.output) {
                // input action
                results[i] = _transfer(action);
                if (action.eip == 0 && action.recipient == address(0x0)) {
                    value = results[i]; // save the ETH value to pass to the next output call
                }
                continue;
            }
            if (action.amount > 0) {
                // track the balances before actions are taken placed
                results[i] = _balanceOf(action.recipient, action.token, action.eip, action.id);
            }
            // output action
            if (action.code != address(0x0)) {
                (bool success, bytes memory result) = action.code.call{value: value}(action.data);
                if (!success) {
                    assembly {
                        revert(add(result,32),mload(result))
                    }
                }
                delete value; // clear the ETH value after transfer
            }
        }
        // verify the balance change
        for (uint i = 0; i < actions.length; ++i) {
            if (actions[i].amount > 0) {
                uint balance = _balanceOf(actions[i].recipient, actions[i].token, actions[i].eip, actions[i].id);
                uint change = balance - results[i];
                require(change >= actions[i].amount, 'UniversalRouter: INSUFFICIENT_OUTPUT_AMOUNT');
                results[i] = change;
            }
        }
        // refund any left-over ETH
        uint leftOver = address(this).balance;
        if (leftOver > 0) {
            TransferHelper.safeTransferETH(msg.sender, leftOver);
        }
    }

    function _transfer(Action memory action) internal returns (uint amount) {
        if (action.eip == 721) {
            IERC721(action.token).safeTransferFrom(msg.sender, action.recipient, action.id);
            return 1;
        }

        if (action.code != address(0x0)) {
            (bool success, bytes memory result) = action.code.call(action.data);
            if (!success) {
                assembly {
                    revert(add(result,32),mload(result))
                }
            }
            amount = abi.decode(result, (uint));
            require(amount <= action.amount, "UniversalRouter::_input: EXCESSIVE_INPUT_AMOUNT");
        } else {
            amount = action.amount;
        }

        if (action.eip == 20) {
            TransferHelper.safeTransferFrom(action.token, msg.sender, action.recipient, amount);
            return amount;
        }
        if (action.eip == 1155) {
            IERC1155(action.token).safeTransferFrom(msg.sender, action.recipient, action.id, amount, "");
            return amount;
        }
        if (action.eip == 0) {
            if (action.recipient != address(0x0)) {
                TransferHelper.safeTransferETH(action.recipient, amount);
            // } else {
            //     reserved for the next output call value
            }
            return amount;
        }
        revert("UniversalRouter::_input: INVALID_EIP");
    }

    function _balanceOf(address owner, address token, uint eip, uint id) internal view returns (uint balance) {
        if (eip == 20) {
            return IERC20(token).balanceOf(owner);
        }
        if (eip == 1155) {
            return IERC1155(token).balanceOf(owner, id);
        }
        if (eip == 721) {
            return IERC721(token).ownerOf(id) == owner ? 1 : 0;
        }
        if (eip == 0) {
            return owner.balance;
        }
        revert("UniversalRouter::_balanceOf: INVALID_EIP");
    }
}
```

## Security Considerations

All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
