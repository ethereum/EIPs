---
eip: 20
title: 代币标准
author: Fabian Vogelsteller <fabian@ethereum.org>, Vitalik Buterin <vitalik.buterin@ethereum.org>
type: Standards Track
category: ERC
status: Final
created: 2015-11-19
---

## 简要说明

一种代币的标准接口。


## 摘要

本标准说明了在智能合约中实现代币的标准 API。 该标准提供了代币的基本功能：如转移代币，授权代币给其他人（如链上第三方应用）使用。


## 动机

标准接口允许以太坊上的任何代币被其他应用程序重用，如钱包、去中心化交易所等。


## 规范

## 代币
### 函数

**注意**:
 - API 规范使用 Solidity 0.4.17（或以上版本）的语法
 - 调用者必须处理 `returns (bool success) ` 返回 `false `。  不能假定 `false `不会返回。


#### 可选函数：name

函数返回代币的名称 - 如 `"MyToken"`。

此函数是可选函数，但是这个函数可以提高代币可用性，不过调用者不能假定这个函数存在。


``` js
function name() public view returns (string)
```


#### 可选函数：symbol

函数返回代币的代号（通常为字母缩写） 例如， "HIX"。

此函数是可选函数，但是这个函数可以提高代币可用性，不过调用者不能假定这个函数存在。

``` js
function symbol() public view returns (string)
```



#### 可选函数：decimals

返回代币使用的小数位数 - 例如: `8`, 意味着要将代币金额除以 `100000000` 来获取其用户表示形式。

此函数是可选函数，但是这个函数可以提高代币可用性，不过调用者不能假定这个函数存在。

``` js
function decimals() public view returns (uint8)
```


#### 函数：totalSupply

返回全部代币供应。

``` js
function totalSupply() public view returns (uint256)
```



#### 函数：balanceOf

返回另一个帐户的帐户余额与地址 `_owner`。

``` js
function balanceOf(address _owner) public view returns (uint256 balance)
```



#### 事件：Transfer

向` _to` 地址转移 `_value` 数量的代币，函数必须触发事件 `Transfer` 。 如果调用方的帐户余额没有足够的令牌，则该函数需要抛出异常。

*注意* 转移 0 个代币也是正常转移动作，同样需要触发 `Transfer` 事件。

``` js
function transfer(address _to, uint256 _value) public returns (bool success)
```



#### 函数：transferFrom

向` _to` 地址转移 `_value` 数量的代币，函数必须触发事件 `Transfer` 。

`transferFrom` 用于提款，允许智能合约代表您转移代币。 例如，这可用于允许智能合约代表你转移代币和/ 或以其他代币收取费用。 SHOULD 功能` throw `，除非 `_from` 帐户通过某些机制有意授权消息的发送者。

*注意* 转移 0 个代币也是正常转移动作，同样需要触发 `Transfer` 事件。

``` js
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
```



#### 函数：approve

授权` _spender` 可以从我们账户最多转移代币的数量 _value</code>，可以多次转移，总量不超过 `_value` 。 这个函数可以再次调用，以覆盖授权额度 `_value`。

为了阻止向量攻击([这里有描述](https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/)和[讨论](https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729))，调用者可以在调整授权额度时，先设置为` 0`，然后在设置为一个其他额度。 智能合约本身不应该强制执行它，以允许向后兼容之前部署的合同。

``` js
function approve(address _spender, uint256 _value) public returns (bool success)
```


#### 函数：allowance

查询 `_owner` 授权给 `_spender` 的额度。

``` js
function allowance(address _owner, address _spender) public view returns (uint256 remaining)
```



### 事件


#### 事件：Transfer

当有代币转移时（包括转移 0），必须触发 Transfer 事件。

如果是新产生代币，触发 Transfer 事件的` _from` 应该设置为 `0x0` 。

``` js
event Transfer(address indexed _from, address indexed _to, uint256 _value)
```



#### 事件：Approval

`approve(address _spender, uint256 _value) `函数成功执行时，必须触发 Approval 事件。

``` js
event Approval(address indexed _owner, address indexed _spender, uint256 _value)
```



## 实现

在以太坊网络上已经有大量符合 ERC20 的代币。 各个团队有不同的实现， 有些注重安全性，有些关注使用更少的矿工费。

#### 实现示例
- [OpenZepelin 实现](https://github.com/OpenZeppelin/openzeppelin-solidity/blob/9b3710465583284b8c4c5d2245749246bb2e0094/contracts/token/ERC20/ERC20.sol)
- [ConsenSys 实现](https://github.com/ConsenSys/Tokens/blob/fdf687c69d998266a95f15216b1955a4965a0a6d/contracts/eip20/EIP20.sol)


## 讨论历史

相关讨论的历史链接：

- Vitalik Buterin 的原始提案：https://github.com/ethereum/wiki/wiki/Standardized_Contract_APIs/499c882f3ec123537fc2fccd57eaa29e6032fe4a
- Reddit 上的讨论： https://www.reddit.com/r/eferum/comments/3n8fkn/lets_talk_about_the_coin_standard/
- 最初的 Issue #20：https://github.com/eysum/EIPs/issues/20



## 版权
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
