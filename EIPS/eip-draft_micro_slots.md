---
eip: <to be assigned>
title: Micro-slots; a convention for storing and retrieving multiple values in a single uint256 slot
author: Timothy McCallum (@tpmccallum)
discussions-to: https://ethresear.ch/t/micro-slots-researching-how-to-store-multiple-values-in-a-single-uint256-slot/5338
status: Draft
type: Informational
created: 2019-04-17
---

## Simple Summary
The uint256 can store any value between 0 and 115792089237316195423570985008687907853269984665640564039457584007913129639935. 
The uint256 data type is the most efficient and effective native Ethereum integer data type. 
This informational EIP provides a standard of using modulo arithmetic and exponentiation to access and store multiple values inside a single uint256 slot.

## Abstract
There are many applications where a smart contract is required to store integer values which are much smaller than uint256. 
Rather than declaring many smaller integers such as uint8 or bit arrays such as bytes1. Using the design pattern in this EIP, a smart contract could declare a single uint256 and then store and retrieve many more values than ordinarily possible.

## Motivation
bytes1 data type can only store 8 bits. Each bytes1 variable can therefore only store between 00000000 and 11111111 (0 to 255).
If a smart contract has 32 bytes1 variables, it can store 32 individual values between 0 and 255; a total of 8160 (32 * 255 = 8160). However, if a smart contract implements this design patter, it could use a single uint256 variable (the equivalent in byte allocation i.e. a single bytes32 variable a.k.a. uint256) to store much more.

## Specification
The upper bound of uint256 is 
```
115792089237316195423570985008687907853269984665640564039457584007913129639935
```

Aside from the digit on the far left, there are 77 remaining digits which can have their value set to between zero and nine (0 to 9). One way to prove this is to execute the following Python3 script which returns the largest possible value of uint256 where all digits equal 9. Warning this test takes a considerable amount of time.

```
big = 115792089237316195423570985008687907853269984665640564039457584007913129639935


for char in str(big):
    if char != '9':
        big = big - 1
        break

print (str(big))
print (len(str(big)))
```

The results from the above test script are as follows

```
99999999999999999999999999999999999999999999999999999999999999999999999999999
77
```


The factors of 77 are 1, 7, 11 and 77 and as such the following micro-slot combinations offer the most efficient storage with the least amount of waste.

1, 77 digit integer with an individual value between 0 and 99999999999999999999999999999999999999999999999999999999999999999999999999999
77, 1 digit integers with an individual value between 0 and 9
7, 11 digit integers with an individual value between 0 and 99999999999
11, 7 digit integers with an individual value between 0 and 9999999

So how are the individual micro-slots accessed?

### Function logic

The following design pattern allows any digit[s] to be obtained from a single uint256 variable

```
((_value % (10 ** _position)) - (_value % (10 ** (_position - _size)))) / (10 ** (_position - _size));

```

### Function arguments

```
_value is the big integer (uint256) which has a range from 0 to 2**256-1
_position is the single digit position (from within _value) from where you would like to begin the extraction
_size is the amount of digits which you would like to extract from _value
```

## Rationale
Creating and interacting with smaller integer data types is marginally more expensive that just using a full uint256. This is because the EVM is designed in such a way that bytes32 and uint256 are the most efficient and effective data types to store and pass around data. Creating new ways to interact with multiple variables in a single uint256 slot may provide potential efficiencies in smart contracts, DApp implementations, Plasma designs and more. The reason that this is an Informative EIP is so that we can reduce/remove duplication of effort, work together to perfect a design pattern and concrete implementation. This EIP provides a standard template in the form of a design pattern. It also provides concrete implementation examples in both Solidity and Vyper.

### Solidity example

The following is a pure function which when passed a uint256 value, as well as a position argument and a size argument, will return a micro portion of the uint256 variable's value.

```
contract uintTool {
    function getInt(uint256 _value, uint256 _position, uint256 _size) public pure returns(uint256){
        uint256 a = ((_value % (10 ** _position)) - (_value % (10 ** (_position - _size)))) / (10 ** (_position - _size));
        return a;
    }
}
```

For example, the above getInt function will return a value of **1234567** if passed the following arguments

```
_value 99999991234567999999999999999999999999999999999999999999999999999999999999999
_position 70
_size 7
```

### Vyper equivalent code example

The following is a constant function (the pure equivalent) which when passed a uint256 value, as well as a position argument and a size argument, will return a micro portion of the uint256 variable's value.

```
@public
@constant
def getInt(_value: uint256, _position: uint256, _size: uint256) -> uint256:
    a: uint256 = ((_value % (10 ** _position)) - (_value % (10 ** (_position - _size)))) / (10 ** (_position - _size))
    return a
```

## Backwards Compatibility
There are no backwards incompatibilities the % and ** are standard features of the EVM already.

## Test Cases
There are no changes to consensus or any base layer technologies. This is only an informational design to allow EOAs and smart contracts to interact more efficiently with the Ethereum data.

## Implementation
This function has been deployed on the Ropsten test network at the following contract address
```
0x488444e7057bd28ba66fcad9862e82286a3c7086
```
The public function can be called and tested by anyone. 

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
