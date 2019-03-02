---
eip: 20
title: ERC-20代币标准
author: Fabian Vogelsteller <fabian@ethereum.org>, Vitalik Buterin <vitalik.buterin@ethereum.org>
type: Standards Track
category: ERC
status: Final
created: 2015-11-19
---

## 简单概要

一个简单的代币接口。


## 摘要

下面的标准允许为智能合约中的代币实现标准API。
这个标准提供了传递代币的基本功能，并且允许代币被许可给另一个链上第三方以便使用它们。

## 目的

一个标准的接口允许Ethereum上的任何代币被其他应用程序重用:从钱包到分布式交换。

## 规范

## 代币
### 方法

**注意**:
 - 以下的规范使用Solidity `0.4.17` (及以上)的语法
 - 调用者必须处理`returns (bool success)`返回的`false`。调用者千万不能假设`false`不会被返回！


#### 名称

返回代币的名称 - 比如`"MyToken"`。

可选 - 这个方法可用来提高可用性，
但接口或其它合约不能假设这些值一定存在。


``` js
function name() public view returns (string)
```


#### 符号

返回代币的符号。比如"HIX"。

可选 - 这个方法可用来提高可用性，
但接口或其它合约不能假设这些值一定存在。

``` js
function symbol() public view returns (string)
```



#### 位数

返回代币的精度位数 - 比如`8`，代表代币数量除以`100000000`以得到其用户表示。

可选 - 这个方法可用来提高可用性，
但接口或其它合约不能假设这些值一定存在。

``` js
function decimals() public view returns (uint8)
```


#### 总量

返回代币的供应总量。

``` js
function totalSupply() public view returns (uint256)
```



#### 余额

返回地址`_owner`的账户代币余额。

``` js
function balanceOf(address _owner) public view returns (uint256 balance)
```



#### 转移

转移`_value`数量的代币到地址`_to`，同时必须发出`Transfer`事件。
如果`_from`账户没有足够的代币进行转移，该函数应当抛出异常(`throw`)。

*注意* 转移数量为0的代币必须被当作正常的转移操作且需要发出`Transfer`事件。

``` js
function transfer(address _to, uint256 _value) public returns (bool success)
```



#### 转移自

从地址`_from`转移`_value`数量的代币到地址`_to`，同时必须发出`Transfer`事件。

`transferFrom`方法被用于存款流程，允许合约以你的名义转移代币。
这通常被用于如允许一个合约以你的名义转移代币并且/或者用代币进行扣费此类场景。
如果`_from`账户没有通过某种机制主动对消息发送者进行授权，则此函数需要抛出异常。

*注意* 转移数量为0的代币必须被当作正常的转移操作且需要发出`Transfer`事件。

``` js
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
```



#### 许可

授权`_spender`从你的账户提现多次，最多提取`_value`数量的代币。如果这个函数被再次调用，它会用`_value`覆盖当前的许可额度。

**注意**: 为了防止像[这里讨论的](https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/)和[这里](https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)的攻击者，
客户端应该确保创建用户界面的方式是：在为相同的支出方将额度设置为另一个值之前，他们首先将额度设置为`0`。
尽管合约本身不应该强制要求，但是允许向后兼容过去部署的合约。

``` js
function approve(address _spender, uint256 _value) public returns (bool success)
```


#### 许可余额

返回`_spender`仍被许可从`_owner`提取的额度。

``` js
function allowance(address _owner, address _spender) public view returns (uint256 remaining)
```



### 事件


#### 转移事件

当代币被转移时必须触发，包括转移0数量的代币。

一个代币合约在创建新代币时应当触发一个`_from`地址被设置为`0x0`的Transfer事件。

``` js
event Transfer(address indexed _from, address indexed _to, uint256 _value)
```



#### 许可事件

在任何成功调用`approve(address _spender, uint256 _value)`时必须触发。

``` js
event Approval(address indexed _owner, address indexed _spender, uint256 _value)
```



## 实现

当前已经有大量的遵循ERC20标准的代币在以太坊网络上部署。
不同的团队编写的不同的实现都各有不同的权衡: 从gas耗费到提高安全性。

#### 下面是可用的实现样例
- [OpenZeppelin implementation](https://github.com/OpenZeppelin/openzeppelin-solidity/blob/9b3710465583284b8c4c5d2245749246bb2e0094/contracts/token/ERC20/ERC20.sol)
- [ConsenSys implementation](https://github.com/ConsenSys/Tokens/blob/fdf687c69d998266a95f15216b1955a4965a0a6d/contracts/eip20/EIP20.sol)


## 历史

跟本标准相关的历史链接:

- 来自Vitalik Buterin的原始提案: https://github.com/ethereum/wiki/wiki/Standardized_Contract_APIs/499c882f3ec123537fc2fccd57eaa29e6032fe4a
- Reddit讨论: https://www.reddit.com/r/ethereum/comments/3n8fkn/lets_talk_about_the_coin_standard/
- 原始issue #20: https://github.com/ethereum/EIPs/issues/20



## Copyright
版权以及相关权利由此[CC0](https://creativecommons.org/publicdomain/zero/1.0/)声明弃权。