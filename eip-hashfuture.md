---
eip: <to be assigned>
title: HashFuture Dividable Asset Token Contract
author: Contract <contract@hashfuture.top>
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2018-10-25
requires: 20
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
This standard defines a smart contract representing ownership and corresponding privileges of realworld asset.
The big token corresponding to ownership of realworld asset can be divided into small tokens representing shares of the asset.
Holder of the big token can claim for the realworld asset, while holders of small tokens can take dividents according to their shares.
Small tokens can be regarded as standard ERC20 tokens, which can exist only after a big token having been splitted into small ones.

This standard keeps backward compatibility with [ERC20].
## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
In this standard, the ownership of a realworld asset is defined as a token(Big Token).Any holder with this big token can claim for the realworld asset from the asset keeper(assigned when the token is issued).The big token will be destructed after the realworld asset has been claimed.
In addition, the big token can be splitted into a designated number of small tokens.
After splitted, the big token will be in 'locked' status, under which several operations are not permitted.
Holders of small tokens can take dividents of the corresponding realworld asset according to their shares.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
This standard extracts the unique verifiable identification and the consistent rights agreement of the realworld asset, including ownership, use rights, income rights, etc., and generates the standardized Big Token in the form of smart contract automatically, thus realizing the decentralized property verification for more realworld assets. This standard will endorse Ethereum with greater value for the real world.
The big token represents a kind of holistic property. Holder of the big token can split the token into a designated number of small tokens. The profit from the asset appreciation will be distributed to the holders of small tokens. Meanwhile, holder of all the small tokens can merge into the big token to exchange the realword asset. Through this process, we can achieve the free conversion of primary assets and secondary assets, greatly reducing transaction costs and promoting the efficient of assets circulation.
The design of the Asset Token Standard can avoid the big shareholders from doing evil. In reality, the major shareholders may encroach on the dividend income of the minority shareholders through the majority rule. On the other hand, it can also prevent small shareholders from extorting the holder who want to collect all the small tokens to exchange the real asset, according to the the ‘collectAllForce’ function. In this way, Situation described by “property is only another name for monopoly” is refrained.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
### Asset Status Brief
There are three metrics describing the status of the asset(big token).
The first one is 'valid'. The big token is in 'valid' status by default and will be 'invalid' once the owner explicitly executes the 'cancelContract' function, which is not revertible.

The second one is 'splitted'. The big token is not 'splitted' by default, and will be 'splitted' after the owner split the big token into small ones. This status is revertible. A holder with all small tokens can merge them into the original big token.

### Preferred Stable Token
The contract specifies a stable token at the initialization phase by assigning the address of a preferred stable token.

The stable token will be used to distribute dividents to share holders or to collect small tokens forcely at the price the owner designated at splitting the big token.

### Asset File Management
#### getAssetFile / setAssetFile
AssetFile includes two parts, a file describing the realworld asset and a file containing legal related documents. These two files are publicly available and can be set at the constructing phase of the smart contract or by explicitly executing 'setAssetFile' or 'setLegalFile' functions by the owner. These two operations require 'unsplitted' and 'valid' status.

```solidity
function initAssetFile(
    string _assetFileUrl, string _assetFileHashType, string _assetFileHashValue,
    string _legalFileUrl, string _legalFileHashType, string _legalFileHashValue
    ) internal;

function setAssetFileLink(string url) public onlyOwner onlyValid onlyUnsplitted;

function setLegalFileLink(string url) public onlyOwner onlyValid onlyUnsplitted;
```


### Asset Trading Management
The big token has a ETH-denominated price specified at initialization, with a 'tradeable' status set to false.
Only the owner can change the 'tradeable' status and set the asset price by calling the function:

```solidity
function setTradeable(bool status) public onlyOwner onlyValid onlyUnsplitted;

function setassetPrice(uint newAssetPrice) public onlyOwner onlyValid onlyUnsplitted;
```

If 'tradeable' is set to true, anyone can acquire the ownership of the big token by sending ETH to a payable function:

```solidity
function buy() public payable onlyValid onlyUnsplitted;
```

This function requires 'valid' and 'unsplitted' status.

### Asset Ownership Management
The owner of a big token can transfer the ownership to another holder under 'valid' and 'unsplitted' status.

```solidity
function transferOwnership(address newowner) public onlyOwner onlyValid onlyUnsplitted;
```

### Asset Cancellation
The cancellation is tightly related to the 'onlyValid' modifier.
After cancellation, the big token enters 'invalid' status.
Only the owner can execute the cancellation function once after the smart contract having been initialized, under unsplitted and valid status.
This operation is not revertible.

```solidity
function cancelContract() public onlyOwner onlyValid onlyUnsplitted;
```

### Asset Split Management
The holder of a big token can split it into a fixed number of small tokens, specifying a buy-back price, a initial token distribution in the meantime.
Note that the buy-back price is stable-token denominated.

```solidity
function split(uint _supply, uint8 _decim, uint _price, address[] _address, uint[] _amount) public onlyValid onlyOwner onlyUnsplitted;
```

This operation requires 'valid' and 'unsplitted' status and can only be executed by the owner.


After splitting, small tokens appear and is compatible with ERC20 standards:


```solidity
/**
 * Standard ERC 20 interface.
 */
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
```

If a holder collects all small tokens, he/she can merge them into the original big token by executing the 'merge' function:
```solidity
function merge() public onlyValid onlySplitted;
```
This function requires the big token is 'splitted' and the executor(i.e, msg.sender) has all the small tokens.

One can forcely collect small tokens from given hoders by calling the 'collectAllForce' function, guaranteed that he/she has approved this contract enough stable token to by the small tokens at the buy-back price.
However, due to the gas limitation of Ethereum, he can not collect all keys with only one call. Hence an agent that can be trusted is need.
The operator is such an agent who will first receive a request to collect all keys, and then collect them with the stable tokens provided by the claimer.

```solidity
function collectAllForce(address[] _address) public onlyOperator;
```

### Asset Dividents Management
If the realworld asset gains income and the corresponding big token has been splitted, then the dividents can be distributed to holders of small tokens according to their shares.
The divident is denominated by the designated stable token.
To distribute dividents, one can call the 'distributeDivident' function, guaranteed that he/she has approved enough stable token to this contract.
In addition, due to the limitation of ethereum, one might not be able to distribute all dividents to all holders by one call, people can call 'partialDistributeDivident' instead, which specifies the amount and corresponding holders to distribute to.

```solidity
function distributeDivident(uint amount) public;

function partialDistributeDivident(uint amount, address[] _address) public;
```


## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
The standard expresses the uniqueness of assets, similar to the exclusive characteristics of ERC721, and expands the mutual conversion between big token and small token. Small token keeps backward compatibility with ERC20.

Through the asset information documents and legal agreements, a bridge linking the real asset in the physical world and tokens in the blockchain world will be established. Compliance with the legal agreements under the laws and regulations of various countries will help token holders to obtain the rights and interests of real assets appreciation and dividends in a legal and compliant manner. At the same time, small tokens will be given the voucher of asset consumption and VIP services, making it more convenient to circulate in the physical world.


## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
Small tokens can be regarded as standard ERC20 tokens, which can only exist after the big token having been splitted.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->


## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
