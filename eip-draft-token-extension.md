## Preamble

    EIP: <to be assigned>
    Title: Token Standard Extension for Centrally Governed Monetary Policy
    Author: Alex Miller
    Type: Standard
    Category: ERC
    Status: Draft
    Created: 2017-05-01
    Requires: ERC20

## Simple Summary
An extension of the ERC20 standard for centrally governed monetary policy.

## Abstract
Two functions and one piece of metadata are added to the ERC20 Token standard for
cases of digitized, centrally controlled assets. These functions act as  levers to increase and decrease the token supply as assets are gained or lost by the issuing institution.

## Motivation
Although the ERC20 token standard has become an overwhelming success, its scope is simply
to define a set of functions and metadata from which to issue and transfer
tokens using a common protocol.

Physical asset issuance use cases are emerging and interest in the ERC20 standard is growing. The standard ERC20 functionality only allows a single issuance event, which is called in the instantiation of the token contract. This restricts a total
supply to a single, immutable value, usually transferred to the contract creator.

Here an extension of the ERC20 token standard is proposed whereby the contract creator
has the ability, in perpetuity, to grow or contract the money supply as inventory is
gained or lost in the physical world. This extension is largely meant for issuance of digital assets backed by deposit or physical goods, though more use cases may emerge.

## Specification
Here two extension functions are introduced. These functions may only be called by the contract creator. Also, a 6th metadata parameter is saved to the contract to record the address of the contract creator. `totalSupply` is reused.

It is important to note that all metadata parameters except for `totalSupply` are
still locked after contract creation, although any token may extend this functionality
outside of the standard.

### increaseSupply

Supply may be increased by the contract creator at any time and by any amount.

```
function increaseSupply(uint value) public returns (bool) {
  if (msg.sender == creator) {
    if (!safeAdd(totalSupply, value)) { throw; };
    if (!safeAdd(balances[creator], value)) { throw; };
    return true;
  }
  return false;
}
```

Where `safeAdd` checks for numerical overflow, e.g.:
```
function safeAdd(uint a, uint b) internal returns (uint) {
  if (a + b < a) { throw; }
  return a + b;
}
```

### decreaseSupply

Supply may be decreased at any time by the creator, but with one caveat:
the creator's token balance must be at least equal to the decrease in supply.

```
function decreaseSupply(uint value) public returns (bool) {
  if (msg.sender == creator) {
    if (balances[creator] < value) { throw; }
    if (!safeSub(totalSupply, value)) { throw; }
    if (!safeSub(balances[creator], value)) { throw; }
    return true;
  }
  return false;
}
```

Where `safeSub` checks for numerical underflow, e.g.:
```
function safeSub(uint a, uint b) internal returns (uint) {
  if (b > a) { throw; }
  return a - b;
}
```

### Changes to instantiation

The `creator` parameter is added to the metadata and is set upon instantiation.

```

mapping( address => uint ) balances;
mapping( address => mapping( address => uint ) ) approvals;
uint public supply;
string public name;
uint8 public decimals;
string public symbol;
string public version;
address public creator;  // <-- New param

function MyToken(uint _supply, string _name, uint8 _decimals, string _symbol, string _version ) {
  balances[msg.sender] = _supply;
  supply = _supply;
  name = _name;
  decimals = _decimals;
  symbol = _symbol;
  version = _version;
  creator = msg.sender;  // <-- Save the creator
}
```

While no function exists in this standard to update the creator, it may
be prudent to allow this transfer of ownership in many (if not most) implementations.

## Rationale

Given the relatively simple nature of the above proposal, one could argue that this
standard is not, strictly speaking, necessary.

It is the opinion of this author that a standardized set of levers with which to control
monetary policy will prove extremely useful as the ecosystem grows and sees increasing
adoption of tokenization as a mechanism to digitize physical or deposit backed assets.

If we wish to allow such assets to be digitized on the Ethereum platform, it becomes
necessary to allow central operators to control the supply of their assets.
These institutions or individuals will demand
the above functionality, as very few organizations see a fixed pool of assets for any
appreciable amount of time. This author believes the existing ERC20 standard is insufficient for these use cases and should be extended in a standardized way.

This proposal is a notable departure from many trustless models that the crypto community
is used to seeing. It is important to note that this proposal is only relevant to digitized
assets already controlled by central issuers and that these models already require trust
in the operator. It is also important to note that if centralized issuers desire this functionality,
they will put it into their token contracts whether or not a standard exists.
The benefit of this standard is to reduce
the amount of redundant innovation as well as the number of errors in individual solutions
to what will likely be a common problem in digital asset issuance.

It is the opinion of this author that a growing number of options for digital assets
distributed on Ethereum is a boon to the ecosystem. Over-collateralized stable coins like Maker
and Stabl are interesting projects, but deposit backed fiat tokens or digitized physical assets
could prove just as valuable for users, provided the issuing counterparty is sufficiently
trustworthy. This standard would allow these counterparties to issue digital assets without
having to roll their own mechanisms with which to control monetary policy.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
