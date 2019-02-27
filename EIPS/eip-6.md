---
eip: 6
title: 重命名 SUICIDE 操作符
author: Hudson Jameson <hudson@hudsonjameson.com>
status: Final
type: Standards Track
category: Interface
layer: Applications
created: 2015-11-22
---

### 概要
本EIP中提出的解决方案是使用`SELFDESTRUCT`替换以太坊编程语言中的`SUICIDE`操作码的名称。

### 目的
对许多人来说，心理健康是一个非常现实的问题，小观念可以带来改变。遭受失败或沮丧的人将从我们的编程语言中看不到自杀这个词中受益。据估计，全球有3.5亿人患有抑郁症。如果我们希望将我们的生态系统发展到所有类型的开发人员，则需要经常审查以太坊编程语言的语义。

由DEVolution，GmbH[由Least Authority执行](https://github.com/LeastAuthority/ethereum-analyses/blob/master/README.md)提交的以太坊安全审计建议如下：
>用“自毁”，“破坏”，“终止”或“关闭”等含义较少的词语替换“自杀”的指令名称，特别是因为这是一个描述合约的自然结果的术语。

我们改变自杀一词的主要原因是为了表明人比代码更重要，而以太坊是一个成熟的项目，可以看到修改的必要性。自杀是一个沉重的主题，我们应该尽一切努力不影响我们的发展社区中患有抑郁症或最近失去身边的人去自杀。以太坊是一个年轻的平台，如果我们在早期实现这一变化，可以减少更多麻烦。

### 实现
`SELFDESTRUCT`被作为`SUICIDE`操作符的一个别名加入(而不是替代它)。
https://github.com/ethereum/solidity/commit/a8736b7b271dac117f15164cf4d2dfabcdd2c6fd
https://github.com/ethereum/serpent/commit/1106c3bdc8f1bd9ded58a452681788ff2e03ee7c
