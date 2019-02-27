---
eip: 2
title: 家园(Homestead)硬分叉修改
author: Vitalik Buterin <v@buterin.com>
status: Final
type: Standards Track
category: Core
created: 2015-11-15
---

### 元信息引用

[Homestead](https://github.com/posa88/EIPs-Chinese/blob/master/EIPS/eip-606.md).

### 参数

|   分叉区块高度   |  链名称  |
|-----------------|-------------|
|    1,150,000    | Main net    |
|   494,000       | Morden      |
|    0            | Future testnets    |

# 规范

如果`block.number >= HOMESTEAD_FORK_BLKNUM`，执行以下操作:

1. 将*通过transaction创建合约*的gas消耗从21,000增加到53,000，也就是说，如果你发送一个transaction到一个空字符串地址，那么初始消耗的gas将是53,000加上tx data花费的gas，而不是现在的21,000。通过`CREATE`操作码进行合约创建则不受影响。
2. 任何所带签名的s值大于`secp256k1n/2`的transaction都会被认为无效。ECDSA恢复预编译合约保持不变，仍继续接受高的s值。这很有用，比如当一个合约恢复旧的比特币签名的时候。
3. 如果创建合约的是否没有没有足够的gas来付需要的最终gas费用，合约创建就会失败(也就是说，gas耗尽)，而不是留下一个空合约。
4. 将当前的难度调整算法公式：`block_diff = parent_diff + parent_diff // 2048 * (1 if block_timestamp - parent_timestamp < 13 else -1) + int(2**((block.number // 100000) - 2))` (其中` + int(2**((block.number // 100000) - 2))`代表指数级的难度调整部分) 修改为 `block_diff = parent_diff + parent_diff // 2048 * max(1 - (block_timestamp - parent_timestamp) // 10, -99) + int(2**((block.number // 100000) - 2))`，其中`//`是整数除法运算符，比如 `6 // 2 = 3`, `7 // 2 = 3`, `8 // 2 = 4`。而`minDifficulty`则仍然定义为最小允许的难度值且调整时不会小于此值。

# 基本原理

目前，通过直接发送transaction来创建合约的方式被过度诱导使用，它的gas开销是21,000，而正常合约创建却要32,000。另外，在自毁退款的帮助下，当前还可以只耗费11,664 gas就能完成简单的ether发送，这样做的代码如下:

```python
from ethereum import tester as t
> from ethereum import utils
> s = t.state()
> c = s.abi_contract('def init():\n suicide(0x47e25df8822538a8596b28c637896b4d143c351e)', endowment=10**15)
> s.block.get_receipts()[-1].gas_used
11664
> s.block.get_balance(utils.normalize_address(0x47e25df8822538a8596b28c637896b4d143c351e))
1000000000000000
```
这并不是一个特别严重的问题，不过这确实是一个bug。

当前允许的s值为`0 < s < secp256k1n`的交易，会带来交易的延展性问题，因为人们可以通过将交易的s值从`s` 改为 `secp256k1n - s`，并翻转v值(`27 -> 28`, `28 -> 27`)，结果的签名却仍然有效。这虽然不是一个严重的安全错误，因为以太坊使用地址进行交易和转账，而不是transaction的哈希值。因此不会有ether被转错，但这仍然会造成UI上的不便。因为攻击者可以让一个确认了的区块中的交易赋予一个不同的哈希使得当用户使用交易哈希作为追踪IDs的时候受到干扰。防止使用大的s值可以消除这个问题。

当合约创建不够gas付最终gas费用的时候让合约创建gas耗尽有如下好处:
- (i) 这给合约创建提供了一种直觉上的"要么成功，要么失败"的特性，而不是像现在"成功，失败，或者空合约"这样的三类状态；
- (ii) 让合约创建失败更容易检测，因为如果合约不成功的话不会有合约账户创建出来；
- (iii) 使得合约创建更安全，比如合约用于接受捐款，那么就要么合约创建成功，要么创建失败而捐款会被退回而不会有一个无效的合约账户接收到这些币。

难度调整上的修改，解决了两个月前出现在Ethereum协议中的问题：大量的矿工在挖包含时间戳为`parent_timestamp + 1`的区块;这使得区块时间分布发生倾斜。我们现在用的算法，会让出块时间的*中值*为13秒，且中值不变的情况下均值却增大。如果51%的矿工都一直这么挖的话，那么均值就会增长到无限大(注：调低的时候减值太多调太低，+1s就挖出来了，随即调高又调太高，很高的秒数才能出块，且加减值越来越大)。提案中的公式则基本锁定均值。可以通过数学证明这个公式的平均区块时间长期来看不会高于24秒。

使用`(block_timestamp - parent_timestamp) // 10`作为主要输入变量而不是直接使用时间差来维护算法的调整粗粒度，避免过度诱导在创建略高难度的区块的时候将时间差设置为1，这能保证不会发生可能导致的分叉。-99的边界是为了保证当出现bug或黑天鹅事件导致两个区块时间差距太大的时候难度调整不会一下调太多。

# 实现

这里通过Python进行了实现:

1. https://github.com/ethereum/pyethereum/blob/d117c8f3fd93359fc641fd850fa799436f7c43b5/ethereum/processblock.py#L130
2. https://github.com/ethereum/pyethereum/blob/d117c8f3fd93359fc641fd850fa799436f7c43b5/ethereum/processblock.py#L129
3. https://github.com/ethereum/pyethereum/blob/d117c8f3fd93359fc641fd850fa799436f7c43b5/ethereum/processblock.py#L304
4. https://github.com/ethereum/pyethereum/blob/d117c8f3fd93359fc641fd850fa799436f7c43b5/ethereum/blocks.py#L42
