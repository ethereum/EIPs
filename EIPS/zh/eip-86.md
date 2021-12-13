---
eip: 86
题目: 交易起源和签名的抽象概念
author: Vitalik Buterin (@vbuterin)
类型: 标准跟踪
分类: 核心
状态: 草案
created: 2017-02-10
---

# 总结

实现一组更改，以“抽象出”签名验证和 `nonce` 检查的组合目的，允许用户创建“帐户合约”来执行任何想要的签名/ `nonce` 检查，而不是使用当前硬编码到事务处理中的机制。

# 参数

* METROPOLIS_FORK_BLKNUM: TBD
* CHAIN_ID: 和用于 `EIP 155` 的相同（即：1用于主网，3用于测试网）
* NULL_SENDER: 2**160 - 1

# 规范

如果 `block.number >= METROPOLIS_FORK_BLKNUM`, 那么:
1. 如果一个交易的签名是 `(CHAIN_ID, 0,0)` （即 `r = s = 0`， `v = CHAIN_ID`)，然后将其视为有效的，并设置发送地址为 `NULL_SENDER`
2. 此形式的交易必须有 `gasprice` = 0, `nonce` = 0, `value` = 0，并且不增加帐户 `NULL_SENDER` 的 `nonce` 。
3. 在 `0xfb` ， `CREATE2` 创建一个新的操作码，带有4个堆栈参数(value, salt, mem_start, mem_size)，将创建地址设置为 `sha3(sender + salt + sha3(init code)) % 2**160` ，其中 `salt` 总是表示为32字节的值。
4. 在所有合约创建操作包括交易和操作码中添加一个规则，如果该地址的合约已经存在，并且有非空代码或非空 `nonce` ，操作失败并返回 `0` ，就好像 `init` 代码已经耗尽 `gas` 一样。如果一个帐户有空代码和 `nonce` 但非空余额，创建操作仍然可以成功。

# 基本原理

这些更改的目标是为帐户安全的抽象概念做准备。我们没有协议机制去把 `ECDSA` 和默认 `nonce` 方案体现作为唯一的“标准”的方式保护一个帐户，而是初步建立一个模型，在长期内所有账户都是合约，合约可以支付 `gas` ，用户可以自由定义他们自己的安全模型。

在 `EIP 86` 下，我们可以期望用户将他们的 `ether` 存储在合约中，其代码可能如下所示(在 `Serpent` 中的例子):

```python
# 从 `tx` 数据获取签名
sig_v = ~calldataload(0)
sig_r = ~calldataload(32)
sig_s = ~calldataload(64)
# 获取 `tx` 参数
tx_nonce = ~calldataload(96)
tx_to = ~calldataload(128)
tx_value = ~calldataload(160)
tx_gasprice = ~calldataload(192)
tx_data = string(~calldatasize() - 224)
~calldataload(tx_data, 224, ~calldatasize())
# 获取签名散列
signing_data = string(~calldatasize() - 64)
~mstore(signing_data, tx.startgas)
~calldataload(signing_data + 32, 96, ~calldatasize() - 96)
signing_hash = sha3(signing_data:str)
# 执行常规检查
prev_nonce = ~sload(-1)
assert tx_nonce == prev_nonce + 1
assert self.balance >= tx_value + tx_gasprice * tx.startgas
assert ~ecrecover(signing_hash, sig_v, sig_r, sig_s) == <pubkey hash here>
# 更新 `nonce`
~sstore(-1, prev_nonce + 1)
# 支付 `gas`
~send(MINER_CONTRACT, tx_gasprice * tx.startgas)
# 进行主调用
~call(msg.gas - 50000, tx_to, tx_value, tx_data, len(tx_data), 0, 0)
# 收回剩余的 `gas`
~call(20000, MINER_CONTRACT, 0, [msg.gas], 32, 0, 0)
```

这可以被认为是一个“转发合同”。它接受数据从“入口点”地址 `2**160 - 1` (一个帐户，任何人都可以发送交易)，期望该数据的格式是 `[sig, nonce, to, value, gasprice, data]` 。转发契约验证签名，如果签名是正确的，它会设置对矿工的付款，然后使用提供的值和数据发送对所需地址的调用。

它提供的好处体现在最有趣的情况下:

- **多重签名钱包**: 目前，从一个多重签名钱包发送需要每个操作被参与者批准，每个批准是一个交易。通过让一个批准交易包含其他参与者的签名，可以简化这一过程，但由于参与者的账户都需要存入 `ETH` ，因此仍然会带来复杂性。有了这个 `EIP` ，合同就可以存储 `ETH` ，直接向合同发送包含所有签名的交易，合同就可以支付费用。
- **环签名混合器**: 环签名混合器的工作方式是N个个体将1个币放入一个合同中，然后使用一个可链接的环签名随后取出1个币。可链接的环形签名确保了取款交易不能与存款关联，但如果有人试图取款两次，那么这两个签名就可以连接起来，阻止第二个签名。然而，目前存在一个隐私风险:要取款，你需要有币来支付 `gas` ，如果这些币没有适当混合，那么你就有可能危及你的隐私。有了这个 `EIP` ，你可以直接用你取出的币支付 `gas` 。
- **自定义加密**: 用户可以升级到 `ed25519` 签名，`Lamport hash` 梯形签名或任何其他他们想要加到自己条款上的方案；他们不需要坚持使用 `ECDSA`。
- **非密码修改**: 用户可以要求交易具有过期时间（这个标准化，将允许旧的空/灰尘帐户安全地从状态中清除），使用 `k` 个并行 `nonces`（一种允许稍微乱序地确认交易的方案，减少交易间的依赖性），或进行其他修改。

（2）和（3）引入一个类似于比特币的 `P2SH` 的功能，允许用户将资金发送到只能映射到一段特定代码的地址。从长远来看，类似这样的东西是至关重要的，因为在所有帐户都是契约的世界中，我们需要保留帐户在链上存在之前发送到那个帐户的能力，因为这是目前存在于所有区块链协议中的基本功能。

# 矿工和交易重放策略

请注意，矿工需要有接受这些交易的策略。这种策略需要具有很强的识别力，否则他们可能会面临接受不向他们支付任何费用的交易的风险，甚至可能会接受没有任何效果的交易（例如：因为事务已经包含在内，所以 `nonce` 不再是当前的）。

一个简单的策略是用一组 `regexp` 和一个账户的目标地址进行检查对比，每个 `regexp` 对应于一个“标准账户类型”，并且是“安全”的（在某种意义上，如果一个帐户有那个代码，并且一个包括账户余额，账户存储和事务数据传递的检查通过，那么，如果交易包含在一个块中，矿工将获得报酬），并挖掘和中继通过这些检查的交易。

一个例子是检查如下:

1. 检查到达地址的代码是上述 `Serpent` 代码的编译版本，将 `<pubkey hash here>` 替换为任何公钥哈希。
2. 检查交易数据中的签名是否使用该密钥哈希进行验证。
3. 检查交易数据中的 `gas` 价格是否足够高
4. 检查状态中的 `nonce` 是否与交易数据中的 `nonce` 匹配
5. 检查帐户中是否有足够的 `ether` 来支付费用

如果五个检查都通过了，中继并/或挖掘交易。

一个松散但仍然有效的策略是接受任何符合上述通用格式的代码，只消耗有限数量的 `gas` 来执行 `nonce` 和签名检查，并保证交易费用将支付给矿工。另一种策略是，与其他方法一起，尝试处理任何要求低于25万 `gas` 的交易，并且只有在矿工的余额在执行交易后适当高于交易前时，才将其纳入交易。

# Copyright

Copyright and related rights waived via CC0.
