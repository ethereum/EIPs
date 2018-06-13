---
eip: <to be assigned>
title: Manager Token Standard
author: Leona Hioki @leohio <leona.hioki@laurus-school.com> ,Kiichi Hiruma @CoRe103<hiruma.kiichi.72n@st.kyoto-u.ac.jp>
discussions-to: leona.hioki@laurus-school.com,@leo_hio(Twitter)
status: Draft
type: Standards
category :ERC
created: 2018-06-15
requires (*optional): <EIP 721>
---

## Simple Summary
Non Fungible Token which can be used in PaaS instead of accounts,API-keys,and serial numbers.

## Abstract
This proposal extends ERC721 token to idenfing owners in any network using a web server,not only in Ethereum Network. Adding a public key to tokens and introducing an order relation enable ERC721 tokens to have practical ID abilities. 
Achieved ID abilities are below.
0 External server can authorize token holder or do Access Control without using Ethereum private key.
1 owner can change account's password or registration at any moment
2 owner can send this NFT to transfer his/her authority without security problems.

## Motivation
Logging in cloud systems by Ethereum address can be done in principle.In addition,policy services or ACL(Access Control List) systems also can be enforced by Ethereum and its clients programs.
"NFT" brought about an appropriate timing to start those practices by its possibility of dealing IDs as assets, which implies sharing API-keys and serial numbers of both dapps/non dapp products. 
In EIP context,By ERC735,Adding attribution to NTFs to claim an ownership in Ethereum was proposed,which is extensible for outer networks because a cypher on chain works at off chain as well.
By ERC1115,DAuth was proposed to login services by NTF,which is extensible to have policy system by adding order relation between tokens,and extensible for usages in PaaS by a simplification of the authorization flow.
By ERC994,the hiearchy NFT was proposed to manage NTFs as social assets which is extensible for PaaS useage by adding authorization functions.

NFT for Cloud/Ethereum half&half system with the minimum extension of ERC721 was needed.

## Specification
####Diaglam
<img src="./assets/eip-X/ManagerTokenSequenceDiaglam.jpg"></img>

#### Attributions

mapping (uint8 => bool) authorityOf;
mapping (uint256 => bool) managersOf;
PublicKey publicKeyOf;

#### Functions
function createToken(address _approver) public;   
function switchManagers(uint256 _fromTokenId, uint256 _toTokenId, uint256 _managerTokenId, bool _propriety) public;
function switchAuthority(uint256 _fromTokenId, uint256 _toTokenId, uint8 _authorityId, bool _propriety) public;
function refreshPublicKey(uint256 _tokenId, string _nOfPublicKey, uint256 _eOfPublicKey) public;
function deleteToken(uint256 _tokenId) public;

## Rationale
####Attributions
mapping (uint8 => bool) authorityOf;
This attribution defines what token owner is authorized to do at off chain.This will be referred in PaaS coding.This usually can not be changed by owner his self.
PublicKey publicKeyOf;
This attribution is used to authorize owners at off chain. Encrypting ,digital signing or emai-sending will be done with this attribution.
mapping (uint256 => bool) managersOf;
This attribution defines order relation between tokens. Owners of a token's manager tokens can change the authority attribution of it.

####Functions
* createToken - Only the person owned the token called 'issuer' can execute this function. After calling, \_approver owns new token. The 'issuer' be the 'manager' of the token automatically.

* switchManagers - Only the 'manager' of the token whose id equals \_toTokenId (call 'toToken' below) can execute this function. The owner of the token whose id equals \_fromTokenId (call 'fromToken' below) change the propriety that the \_managerTokenId is included in managers of 'toToken' into \_propriety.

* switchAuthority - As switchManagers, \_fromTokenId owner change the propriety that the \_authorityId is included in authoritys of 'toToken' into \_propriety. But this function caller must own the token with the \_authorityId, in addition.

* refreshPublicKey - Only the token owner can execute this function. The owner resister the value equivalent to the 'n' and 'e' of RSA cryptosystems. By using these values, the owner allow someone to encrypto confidential data and anyone can decrypto the sign by the corresponded private key in advance.

* deleteToken - Only the token owner and issuer can execute this function. After calling, the token whose id equals \_tokenId delete.

<img src="./assets/eip-X/createTokenfunction.jpg"></img>
<img src="./assets/eip-X/refreshPublicKeyfunction.jpg"></img>
<img src="./assets/eip-X/switchAuthorityfunction.jpg"></img>

## Backwards Compatibility(ERC721)
This standard has no backwards compatibility.This is a NFT standard for cloud usages with the minimum extension of ERC721.
And this is not the extension of ERC735,ERC998,ERC1115. 

## Test Cases
Demo is here.Please install Metamask and access with a pc.
<a href="https://www.geomerlin.com/blog/managertoken.html">Enter Demo</a>
The sample solidity code is on link below.
<a href="https://github.com/geo-merlin/infraOnEthereum/blob/PLCdemo/sol/ManagerToken.sol">ManagerToken.sol</a>

## Implementation
Examples of the implemention can be executed at the demo above.
Design patterns of this standard are below.

####Cloud Usage
<img src="./assets/eip-X/ManagerToken.jpg"></img>
1.Requesting a server to execute a function which is authorized with the authority_attribution of the token, and the sign by the private key
2.Server check the sign by the public key,execute the function,and returns the result.

####Sending Token
1.The current owner sends token to another,and transfers the authority,with the public key unchanged.
2.The receiver changes the public key not to let the previous owner use the token.
3.The manager sets the new authority for the token.

####Manager Relation
(1)OneManagerPattern
If a token has only one manager,there are two pattern to manage.
1. allow a higher manager of the token change the authority(authorityOf)
2. don't allow any higher manager of the token change the authority(authorityOf)

(2)SeveralManagerPattern
If a token can have several managers,conflicts of editing authority will occur.
switchAuthority function can describe this pattern,and this depends on a developper's thought.
The codes in the demo above let them conflict,and requires nothing.
<img src="./assets/eip-X/conflict.jpg"></img>

(3)OneIssuerPattern
If all tokens are allowed to be created by one address,
createToken function should require the address check.
If createToken function require the token Id,the constructor function should create one token initially.
<img src="./assets/eip-X/createToken.jpg"></img>

(4)SeveralIssuerPattern
If token holders can create new tokens,there can be unlimited number of tokens.
Developpers should make rule by limitting CreateToken function to a certain extent.

##To be Discussed
This proposal is motivated by one belief that Ethereum itself should be introduced to real Cloud Administrator's jobs in the recent phase.

Then the difference of these diagrams below leads to the questions,"what is the Ethereum's role in Clouds?" and "What is the minimum token standard to be used by Cloud Admins today?"
<img src="./assets/eip-X/ManagerTokenBefore.jpg"></img>
<img src="./assets/eip-X/ManagerToken.jpg"></img>

As an economical aspect of Manager Token Standard(MTS),this frees product sellers from fixed pricing mistakes by effects of free markets,
and gives them opptunities to open crowd sales instead of sign-up of API-keys or serial numbers. 

Some of the discussions should reach what the simplest MTS implementation for managing and marketing system is.
And these show which task tokens can be used in.
<img src="./assets/eip-X/comparingBlockchainCloud.jpg"></img>
(quoted from <a href="https://ieeexplore.ieee.org/document/7930226/">Comparing Blockchain and Cloud Services for Business Process Execution</a>)
These discussions are also held in <a href="https://join.slack.com/t/geomarlin/shared_invite/enQtMzYyNTQ1MjEyNjYwLWRiNTY0M2NiYjFmYTYwMzMzMmRiNTMyOTE4MWZlNzg5YjJmOTdiNTI1ODJiNGI5NWY2ZTJjZWEwZTFkYzFmMzY">Slack</a> 

##Refereunce
<a href="https://github.com/ethereum/EIPs/issues/721">[1]ERC721</a>
<a href="https://github.com/ethereum/EIPs/issues/935">[2]ERC935</a>
<a href="https://github.com/ethereum/EIPs/issues/994">[3]ERC994</a>
<a href="https://github.com/ethereum/EIPs/issues/1115">[4]ERC1115</a>
<a href="https://ieeexplore.ieee.org/document/7930226/">[5]Comparing Blockchain and Cloud Services for Business Process Execution</a>
<a href="https://azure.microsoft.com/es-es/blog/introducing-enterprise-smart-contracts/">[6]Introducing Enterprise Smart Contracts</a>
