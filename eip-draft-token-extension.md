## Preamble

    EIP: <to be assigned>
    Title: Token Standard Extension for Increasing & Decreasing Supply v0.1
    Author: Alex Miller
    Type: Standard
    Category: ERC
    Status: Draft
    Created: 2017-05-01
    Requires: ERC20

## Simple Summary
An extension of the ERC20 standard for increasing and decreasing supply.

## Abstract
Two functions are added to the ERC20 Token standard. These functions act as levers to increase and decrease the token supply.

## Motivation
Although the ERC20 token standard has become an overwhelming success, its scope is simply to define a set of functions and metadata from which to issue and transfer tokens using a common protocol.

Physical asset issuance use cases are emerging and interest in the ERC20 standard is growing. The basic ERC20 functionality only allows a single issuance event, which is called in the instantiation of the token contract. This restricts a total supply to a single, immutable value, usually transferred to the contract creator.

Here an extension of the ERC20 token standard is proposed whereby `totalSupply` of the token may be modified in perpetuity. Implementations are encouraged to restrict this functionality to whatever party is reasonable (e.g. the contract creator, or some other `owner` of the token).

## Specification
Here two extension functions are introduced, which act as levers with which to modify the token supply.

### mint

Supply may be increased at any time and by any amount by minting new tokens and transferring them to a desired address. Again, adding ownership modifiers and restricting privileges would prove useful in most cases.

```
function mint(uint value, address for) public returns (bool) {
  totalSupply = safeAdd(totalSupply, value);
  balances[for] = safeAdd(balances[for], value);
  Transfer(0, for, value);
  return true;
}
```

Where `safeAdd` checks for numerical overflow, e.g.:
```
function safeAdd(uint a, uint b) internal returns (uint) {
  if (a + b < a) { throw; }
  return a + b;
}
```

### burn

Supply may be decreased at any time by subtracting from a desired address. There is one caveat: the token balance of the provided party must be at least equal to the amount being subtracted from total supply.

```
function burn(uint value, address from) public returns (bool) {
  balances[from] = safeSub(balances[from], value);
  totalSupply = safeSub(totalSupply, value);  
  Transfer(from, 0, value);
  return true;
}
```

Where `safeSub` checks for numerical underflow, e.g.:
```
function safeSub(uint a, uint b) internal returns (uint) {
  if (b > a) { throw; }
  return a - b;
}
```

## Rationale

It is the opinion of this author that a standardized set of levers with which to control supply will prove extremely useful as the ecosystem grows and sees increasing adoption of tokenization as a mechanism to digitize physical or deposit backed assets.

If we wish to allow such assets to be digitized on the Ethereum platform, it becomes necessary to allow central operators to control the supply of their assets. These institutions or individuals will demand the above functionality, as very few organizations see a fixed pool of assets for any appreciable amount of time. This author believes the existing ERC20 standard is insufficient for these use cases and should be extended in a standardized way.

This proposal is a notable departure from many trustless models that the crypto community is used to seeing. It is important to note that this proposal is mostly relevant to digitized assets already controlled by central issuers and that these models already require trust in the operator. However, use cases may emerge whereby mint/burn privileges may be extended on a one-time-use basis. It is also important to note that if centralized issuers desire this functionality, they will put it into their token contracts whether or not a standard exists.
The benefit of this standard is to reduce the amount of redundant innovation as well as the number of errors in individual solutions to what will likely be a common problem in digital asset issuance.

It is the opinion of this author that a growing number of options for digital assets distributed on Ethereum is a boon to the ecosystem. Over-collateralized stable coins like Maker and Stabl are interesting projects, but deposit backed fiat tokens or digitized physical assets could prove just as valuable for users, provided the issuing counterparty is sufficiently trustworthy. This standard would allow these counterparties to issue digital assets without having to roll their own mechanisms with which to control monetary policy.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
