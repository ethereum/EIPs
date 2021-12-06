---
eip: 7
title: DELEGATECALL
author: Vitalik Buterin <v@buterin.com>
status: 最终
type: 标准跟踪
category: 核心
created: 2015-11-15
---

### 硬分叉
[Homestead](./eip-606.md)

### 参数
- 激活:
  - 主网上的区块 >= 1,150,000
  - `Morden` 上的区块 >= 494,000
  - 未来的测试网上的区块 >= 0

### 概述

在 `0xf4` 添加一个新的操作码 `DELEGATECALL` ，这在思想上类似于 `CALLCODE` ，除了它将发送方和值从父范围传播到子范围，即创建的调用具有与原始调用相同的发送方和值。

### 规范

`DELEGATECALL`: `0xf4`, 接受6个操作数:
- `gas`: 代码执行时可能使用的 `gas` 量;
- `to`: 要执行代码的目的地址;
- `in_offset`: 输入到内存的偏移量;
- `in_size`: 输入的字节大小;
- `out_offset`: 输出到内存的偏移量;
- `out_size`: 输出的草稿板的大小。

#### `gas` 注意事项
- 没有发放基本津贴; `gas` 是被调用者收到的总金额。
- 像 `CALLCODE` ，帐户创建从来没有发生，所以前期的 `gas` 成本总是 `schedule.callGas` + `gas` 。
- 未使用的 `gas` 正常退还。

#### 发送者说明
- `CALLER` 和 `VALUE` 在被调用者的环境中表现得和在调用者的环境中一样。

#### 其他事项
- 1024的深度限制仍然保持正常。

### 基本原理

将发送者和值从父范围传播到子范围更便于合约存储另一个地址作为可变资源代码和 ''pass through'' 调用它,子代码和父代码是在本质上相同的环境(减少 `gas` 和增加 `callstack` 深度除外)中执行。

用例1:分割代码得到大约 3m `gas` 屏障

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

用例2:用于存储合约代码的可变地址:

```python
if ~calldataload(0) / 2**224 == 0x12345678 and self.owner == msg.sender:
    self.delegate = ~calldataload(4)
else:
    ~delegate_call(msg.gas - 10000, self.delegate, 0, ~calldatasize(), ~calldatasize(), 10000)
    ~return(~calldatasize(), 10000)
```
这些方法调用的子函数现在可以自由地引用 `msg.sender` 和 `msg.value` 。

### 可能反对的理由

*你可以复制这个功能，只要把发送者插入到调用数据的前20个字节。然而，这将意味着代码将需要专门为委托合约进行编译，并且不能同时在委托环境和原始环境中使用
