---
title: <The EIP title is a few words, not a complete sentence>
description: <Description is one full (short) sentence>
author: <a comma separated list of the author's or authors' name + GitHub username (in parenthesis), or name and email (in angle brackets).  Example, FirstName LastName (@GitHubUsername), FirstName LastName <foo@bar.com>, FirstName (@GitHubUsername) and GitHubUsername (@GitHubUsername)>
title: TCT
description: TCT combines the benefits of runtime checking and symbolic proof. The unique design of TCT ensures that the theorems are provable and checkable in an efficient manner.
author: Shuo Chen (@cs0317), Nikolaj Bjørner (@NikolajBjorner), Tzu-Han Hsu (@tzuhancs), Ashley Chen (@ash-jyc), Nanqing Luo (@Billy1900)
discussions-to: https://discord.gg/WJKNcsudR9
status: Draft
type: <Standards Track, Meta, or Informational>
category: <Core, Networking, Interface, or ERC> # Only required for Standards Track. Otherwise, remove this field.
created: <date created on, in ISO 8601 (yyyy-mm-dd) format>
type: Standards Track
category: Core
created: 2023-10-04
requires: <EIP number(s)> # Only required when you reference an EIP in the `Specification` section. Otherwise, remove this field.
---

<!--
  READ EIP-1 (https://eips.ethereum.org/EIPS/eip-1) BEFORE USING THIS TEMPLATE!

  This is the suggested template for new EIPs. After you have filled in the requisite fields, please delete these comments.

  Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

  The title should be 44 characters or less. It should not repeat the EIP number in title, irrespective of the category.

  TODO: Remove this comment before submitting
-->

## Abstract

<!--
  The Abstract is a multi-sentence (short paragraph) technical summary. This should be a very terse and human-readable version of the specification section. Someone should be able to read only the abstract to get the gist of what this specification does.

  TODO: Remove this comment before submitting
-->

Smart contracts are crucial elements of decentralized technologies, but they face significant obstacles to trustworthiness due to security bugs and trapdoors. To address the core issue, we propose a technology that enables programmers to focus on design-level properties rather than specific low-level attack patterns. Our proposed technology, called Theorem-Carrying-Transaction (TCT), combines the benefits of runtime checking and symbolic proof. Under the TCT protocol, every transaction must carry a theorem that proves its adherence to the safety properties in the invoked contracts, and the blockchain checks the proof before executing the transaction. The unique design of TCT ensures that the theorems are provable and checkable in an efficient manner. We believe that TCT holds a great promise for enabling provably secure smart contracts in the future.

## Motivation

<!--
  This section is optional.

  The motivation section should include a description of any nontrivial problems the EIP solves. It should not describe how the EIP solves those problems, unless it is not immediately obvious. It should not describe why the EIP should be made into a standard, unless it is not immediately obvious.

  With a few exceptions, external links are not allowed. If you feel that a particular resource would demonstrate a compelling case for your EIP, then save it as a printer-friendly PDF, put it in the assets folder, and link to that copy.

  TODO: Remove this comment before submitting
-->

This proposal is necessary since the Ethereum protocol does not ensure the safety features on the design level. It stems from the recognition of the significant obstacles faced by smart contracts in terms of trustworthiness due to security bugs and trapdoors. While smart contracts are crucial elements of decentralized technologies, their vulnerabilities pose a challenge to their widespread adoption. Conventional smart contract verification and auditing helps a lot, but it only tries to find as many vulnerabilities as possible in the development and testing phases. However, in real cases, we suffer from the unintentional vulnerabilities and logical trapdoors which lead to lack of transparency and trustworthiness of smart contract.

## Specification

<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting

  The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.
-->

First, we give several terminology:
- $\tau$: it denotes the theorem. Every transaction must carry a theorem that proves its adherence to the specified safety properties in the invoked contracts.
- $\mathrm{f}$: it denotes the entry function of transaction.
- $\varphi(\mathrm{V}, \mathrm{s})$: $\varphi$ denotes hypothesis which defined over input parameter $\mathrm{V}$ and blockchain state $\mathrm{s}$.
- $\mathrm{h}$: code path hash which is used for execution path match.
- Invariant: contract invariants like the ones are ensured before and after every transaction. They contain quantifiers, sum of map, etc., so are difficult to check concretely.

$$
\tau::=(\mathrm{f}, \varphi(\mathrm{V}, \mathrm{s}), \mathrm{h})
$$

The above theorem means​ for any transaction started by invoking $\mathrm{f}$ when $\varphi$ is satisfied, if it is completed (i.e., not reverted by EVM) and the hash of the code path equals $\mathrm{h}$, then all the assertions along the code path are guaranteed to hold. ​

## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

## Backwards Compatibility

<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

No backward compatibility issues found.

## Test Cases

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

We extract a token contract from this [blog](https://blog.chain.link/reentrancy-attacks-and-the-dao-hack/) as shown below:

```solidity
// SPDX-License-Identifier: MIT

/* Vulnerability examples:

   reentrancy:
   https://blog.chain.link/reentrancy-attacks-and-the-dao-hack/

   integer overflow:
   https://peckshield.medium.com/integer-overflow-i-e-proxyoverflow-bug-found-in-multiple-erc20-smart-contracts-14fecfba2759
*/
pragma solidity >=0.8.0;

abstract contract Token {
    address public owner;
    uint256 public totalSupply;
    function balanceOf(address _owner) public view virtual returns (uint256 balance);
}

/// @custom:tct invariant: forall x:address :: 0 <= balances[x] && balances[x] <= totalSupply
/// @custom:tct invariant: sum(balances) == totalSupply 
abstract contract StandardToken is Token {

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }

    mapping (address => uint256) balances;
}

contract MultiVulnToken is StandardToken {
    string public name = "Demo token with reentrancy issue, integer overflow and access control issue";
    constructor (uint256 initialSupply) {
        totalSupply = initialSupply;
        balances[msg.sender] = totalSupply;
    }
    function transferProxy(address _from, address _to, uint256 _value, uint256 _fee
        ) public returns (bool){
		unchecked{
			require(balances[_from] >= _fee + _value);
			require(balances[_to] + _value >= balances[_to]);
			require(balances[msg.sender] + _fee >= balances[msg.sender]); 
			
			balances[_to] += _value;
			balances[msg.sender] += _fee;
			balances[_from] -= _value + _fee;
			return true;
		}
    }

    //This function moves all tokens of msg.sender to the account of "_to"
    function clear(address _to) public {
        uint256 bal = balances[msg.sender];
        require (msg.sender!=_to);
        balances[_to]+=bal;
        bool success;
        (success, ) = msg.sender.call(
            abi.encodeWithSignature("receiveNotification(uint256)", bal)
        );
        require(success, "Failed to notify msg.sender");
        balances[msg.sender] = 0;
    }
}

//========================================================
contract reentrancy_attack {
    MultiVulnToken public multiVulnToken; 
    address _to;
    uint count=0;
    constructor (MultiVulnToken _multiVulnToken, address __to) 
    {
        multiVulnToken=_multiVulnToken;
        _to = __to;
    }
    function receiveNotification(uint256) public { 
        if (count < 9) {
            count ++;
            multiVulnToken.clear(_to); 
        }
    } 
    function attack() public {
        multiVulnToken.clear(_to);
    }
}

contract Demo {
    MultiVulnToken MultiVulnTokenContractAddress;

    address attacker1Address = address(0x92349Ef835BA7Ea6590C3947Db6A11EeE1a90cFd); //just an arbitrary address
    reentrancy_attack attacker2Address1;
    address attacker2Address2 = address(0x0Ce8dAf9acbA5111C12B38420f848396eD71Cb3E); //just an arbitrary address
    
    constructor () {
        MultiVulnTokenContractAddress = new MultiVulnToken(1000);
        attacker2Address1 = new reentrancy_attack(MultiVulnTokenContractAddress,attacker2Address2);

        //suppose attacker3Address1 has 5 tokens initially
        MultiVulnTokenContractAddress.transferProxy(address(this), address(attacker2Address1),5,0
                                      );
    }

    function getBalanceOfAttacker1() view public returns (uint256){
        return MultiVulnTokenContractAddress.balanceOf(attacker1Address);
    }
    function attack1_int_overflow() public {
        MultiVulnTokenContractAddress.transferProxy(address(this), 
                                      attacker1Address,
                                      uint256(2**255+1),
                                      uint256(2**255)
                                      );
    }

    function getBalanceOfAttacker2() view public returns (uint256){
        return MultiVulnTokenContractAddress.balanceOf(address(attacker2Address1))
            +  MultiVulnTokenContractAddress.balanceOf(attacker2Address2);
    }
    function attack2_reentrancy() public {
        attacker2Address1.attack();
    }
}
```

Note that we have provided the invariant for the entry functions above `abstract contract StandardToken`. Since TCT enables behavioral subtyping for smart contract, it still delivers its children contract such as `MultiVulnToken`.

For the contract `MultiVun`, we have provided a theorem for the entry function of transaction as below
```json
{
	"entry-for-test":"MultiVulnToken::clear(address)",
	"entry-for-real":"0x88c436e4a975ef5e5788f97e86d80fde29ddd13d::0x3d0a4061",
	"def-vars": {
		"totalSupply": ["", "this.totalSupply", "uint256"]
	},
	"hypothesis": [
		"totalSupply < TwoE256 && tx_origin != _to"
	],
	"path-hash-for-test": "*",
	"path-hash-for-real": "the real hash (not implemented yet)",
	"numerical-type": "int"
}
```

If attacker’s obligation to prove the theorem, the attempt would be doomed to fail.​

## Reference Implementation

<!--
  This section is optional.

  The Reference Implementation section should include a minimal implementation that assists in understanding or implementing this specification. It should not include project build files. The reference implementation is not a replacement for the Specification section, and the proposal should still be understandable without it.
  If the reference implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed.

  TODO: Remove this comment before submitting
-->

We have build a MVP version of TCT mechanism in the [demo repo](https://github.com/TCT-web3/demo). What's more, We have integrated TCT mechanism into current Geth in the [TCT-Geth](https://github.com/TCT-web3/TCT-Geth).

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
