---
eip: 7
title: 委托调用(DELEGATECALL)
author: Vitalik Buterin <v@buterin.com>
status: Final
type: Standards Track
category: Core
created: 2015-11-15
---

### 硬分叉
[家园](https://github.com/posa88/EIPs-Chinese/blob/master/EIPS/eip-606.md)

### 参数
- 激活:
  - 主网在区块高度 >= 1,150,000 时
  - Morden网络在区块高度 >= 494,000 时
  - 其他未来测试网络在区块高度 >= 0 时

### 概要

增加一个新操作码`DELEGATECALL`在`0xf4`，类似于`CALLCODE`，但它将来自父作用域的sender和值传播到子作用域，也就是说，该调用拥有和原始调用一样的sender和值。

### 规范

`DELEGATECALL`: `0xf4`，有6个操作数:
- `gas`: 代码执行时可能使用的gas数量；
- `to`: 要执行其代码的目的地地址；
- `in_offset`: 输入到内存中的偏移量；
- `in_size`: 输入的字节大小；
- `out_offset`: 输出到内存中的偏移量；
- `out_size`: 输出到高速暂存存储器的字节大小。

#### gas的说明
- 没有基本薪酬；`gas`是被调用函数收到的所有数量。
- 就像`CALLCODE`一样，账户创建永远不会发生，因此前期的gas成本始终是`schedule.callGas` +`gas`。
- 未使用的gas正常退还。

#### sender的说明
- `CALLER`和`VALUE`在被调用者的环境中的行为与在调用者的环境中的行为完全相同。

#### 其他说明
- 1024的深度限制仍然正常保留。

### 基本原理

将来自父作用域中的sender和值传播到子作用域中能使得合约更容易将另一个地址存储为可变代码源并对其进行传递调用，因为子代码可以执行在基本和父代码一样的环境下(除了减少的gas耗费和增加的调用栈深度)。

用例1: 切分代码以规避3m的gas限制

```python
~calldatacopy(0, 0, ~calldatasize())
if ~calldataload(0) < 2**253:
    ~delegate_call(msg.gas - 10000, $ADDR1, 0, ~calldatasize(), ~calldatasize(), 10000)
    ~return(~calldatasize(), 10000)
elif ~calldataload(0) < 2**253 * 2:
    ~delegate_call(msg.gas - 10000, $ADDR2, 0, ~calldatasize(), ~calldatasize(), 10000)
    ~return(~calldatasize(), 10000)
...
```

用例2: 使用可变地址来存储合约的代码:

```python
if ~calldataload(0) / 2**224 == 0x12345678 and self.owner == msg.sender:
    self.delegate = ~calldataload(4)
else:
    ~delegate_call(msg.gas - 10000, self.delegate, 0, ~calldatasize(), ~calldatasize(), 10000)
    ~return(~calldatasize(), 10000)
```
这些方法调用的子函数现在就可以自由地引用`msg.sender`和`msg.value`。

### 可能的反对意见

* 你可以通过仅仅粘贴发送者到调用数据的前20字节中来复制这个功能。但是，这意味着代码需要专门为委托合约编译，并且不能同时在委托和原始上下文中使用。
