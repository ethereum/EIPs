---
eip: <to be assigned>
title: 2-Factor Auhenication for transfering ownership
author: Zach Burks (@VexyCats)
discussions-to: https://ethereum-magicians.org/t/discussion-around-2fa-implementation-within-smart-contracts/924
status: Draft
type: Standards Track
category: ERC
created: 2018/08/01
---

## Simple Summary


2 factor authenication can be setup in a smart contract system, so that a 2FA code is required as extra data in order to execute some function.

## Abstract

Using RegisteredAgents to update a central smart contract with a generated 2FA code, can help provide a third party level security over smart contract's transactions. If a user wants to interact with a contract that uses 2FA, they would be required to log into a third party website via traditional authenication means, and then generate a new 2FA that is then sent to the smart contract via a registeredAgent. Then User can then transact with the smart contract but including the 2FA code within their transaction. This provides a username/password combo as a second layer over your private key. Using this system, in order for someone to steal your funds from the smart contract, they would need access to your private key, and now the login credidentals for the third party website. Preventing theft of funds, if a private key is lost/stolen. 

## Motivation

Motivation comes from international travel. If I have XYZ tokens but I'm travelling aboard, if my private key is stolen while travelling, there will be no updates/emails/messages that alert me that my XYZ tokens have been moved. This means, when I get back home, or check my wallet, I'll see the balance as 0. To prevent this, using 2FA as a multisig wallet between a trusted third party and yourself, without sharing the actual private keys is one solution. Now, if I am traveling and someone wanted to move my ZYX tokens, they would need to have hacked my 3rdparty2fa.com account to get access to, and also, generate, a 2FA code needed to transfer my tokens. 

## Specification


   pragma solidity ^0.4.21;


   contract manager2FA {
    
    mapping(address => bool) public registeredAgent;
    modifier onlyRegisteredAgent {

    require(registeredAgent[msg.sender] == true);
    _;
    }
    
    //time in unix timestamp
    uint256 constant TIMELIMIT = 500;
    mapping(address => uint) public codesToAddress;    
    mapping(address => mapping(uint256 => uint256)) public addressToDatatoTime;
    address public owner;
    //getters
    
    constructor(){
        owner = msg.sender;
    }
     function verifyTx(address _sender, uint256 _2FAcode) returns (bool){
        //check that timelimit is not expired by checking the timestamp the code was generated + 500.
        require(now < (addressToDatatoTime[_sender][_2FAcode] +500));
        // needs to verify that the person has the correct 2FA
        require(codesToAddress[_sender] == _2FAcode);
        return true;
                }
    
    //set 2FA called from registeredAgent which is running on the backend of some companies servers
       function set2FA(address _sender, uint256 _2FAcode) 
       onlyRegisteredAgent 
       returns (uint256)  
      {
            codesToAddress[_sender] = _2FAcode;
            //this setting the time on the code for that address, to the current time. 
            addressToDatatoTime[_sender][_2FAcode] = now;
            
        return addressToDatatoTime[_sender][_2FAcode];
            
        }
    
    function registerAgent(address _agent) returns (bool){  
        require(msg.sender == owner);
        require(registeredAgent[_agent] == false);
        registeredAgent[_agent] = true;
        return registeredAgent[_agent];
    }
    
}
---
## Rationale

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

## Backwards Compatibility

<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
Not backwards compatible. 

## Test Cases


   pragma solidity ^0.4.21;

   import "./manager2fa.sol";

   contract Test2FA {
    
    
     manager2FA instance;
    
    function setAddress(address _addr){
        
        instance = manager2FA(_addr);
    }
   function confirmCode(uint256 _2FAcode) returns (bool){
       require(instance.verifyTx(msg.sender, _2FAcode));
       return true;
       
   }
    
   }

## Implementation

Coming soon. Need feedback on whether each contract implementing the 2FA standard should be required to run their own registeredAgent, meaning every 2FA contract out there, would be its own login/3rd party registeredAgent. Or, one general Smart contract for the entire Ethereum Ecosystem, where registeredAgents are able to be added for individual contracts. The latter is a single point of failure, but allows for a 2FA smart contract to exsist on the mainnet for everyone to use. 

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
