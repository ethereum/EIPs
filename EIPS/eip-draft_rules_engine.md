---
eip: <to be assigned>
title: Rules Engine Standard
author: Aaron Kendall (@jaerith), Juan Blanco <@juanfranblanco>
discussions-to: <URL>
status: Draft
type: Standards Track
category : ERC
created: 2020-06-20
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
An interface for using a smart contract as a rules engine.  A single deployed contract can register a data domain, create sets of rules that perform actions on that domain, and then invoke a set as an atomic transaction. 

## Abstract
This standard proposes an interface that will allow the creation of hierarchal sets of rules (i.e., RuleTrees) that can be invoked to evaluate and manipulate a registered data domain.  At the time of this draft, all intentions to insert additional functionality onto the blockchain requires the coding and creation of a newly deployed contract.  However, this standard will allow users to deploy a contract just once, one which will then allow them to create (and invoke) pipelines of commands within that contract.

## Motivation
At the time of this draft, all development for Ethereum requires writing the code that forms smart contracts and then deploying those contracts to Ethereum.  This requirement pertains to all cases, even for simple cases of examining a value and/or altering it.  However, less technical companies and users might also want to configure and deploy simple functionality onto the chain, without knowing the reveleant languages or details necessary.  By having the data domain and the predefined actions implemented along with this interface, a deployed instance of such a contract can provide functionality to no-code or little-code clients, allowing more users of various technical proficiency to interact with the Ethereum ecosystem.

## Specification
For the clarification of terminology, an Attribute is a registered data point within the data domain, representing data that exists either in the rules engine contract or elsewhere.  A Rule is an predefined action that occurs upon a single data point (i.e., Attribute) in the predefined data domain.  For example, a Rule could check whether the Attribute 'TokenAmt' has a value less than the RHL (i.e., right-hand value) of 10.   A RuleSet is a collection of Rules, where their collection invocation creates a boolean result that determines the navigational flow of execution between RuleSets.  A RuleTree is a collection of RuleSets that are organized within a hierarchy, where RuleSets can contain other RuleSets.

```solidity
pragma solidity ^0.6.0;

/**
    @title ERC-#### Rules Engine Standard
    @dev See https://eips.ethereum.org/EIPS/eip-####
 */
 interface ERCRulesEngine {

    /**
        @dev Should emit when a RuleTree is invoked.
        The `ruler` is the ID and owner of the RuleTree being invoked.  It is also likely msg.sender.
    */
    event CallRuleTree(
        address indexed ruler
    );

    /**
        @dev Should emit when a RuleSet is invoked.
        The `ruler` is the ID and owner of the RuleTree in which the RuleSet is stored.  It is also likely msg.sender.
        The 'ruleSetId' is the ID of the RuleSet being invoked.
    */
    event CallRuleSet(
        address indexed ruler,
        bytes32 indexed tmpRuleSetId
    );

    /**
        @dev Should emit when a Rule is invoked.
        The `ruler` is the ID and owner of the RuleTree in which the RuleSet is stored.  It is also likely msg.sender.
        The 'ruleSetId' is the ID of the RuleSet being invoked.
        The 'ruleId' is the ID of the Rule being invoked.
        The 'ruleType' is the type of the rule being invoked.        
    */
    event CallRule(
        address indexed ruler,
        bytes32 indexed ruleSetId,
        bytes32 indexed ruleId,
        uint ruleType
    );

    /**
        @dev Should emit when a RuleSet fails.
        The `ruler` is the ID and owner of the RuleTree in which the RuleSet is stored.  It is also likely msg.sender.
        The 'ruleSetId' is the ID of the RuleSet being invoked.
        The 'severeFailure' is the indicator of whether or not the RuleSet is a leaf with a 'severe' error flag.
    */
    event RuleSetError (
        address indexed ruler,
        bytes32 indexed ruleSetId,
        bool severeFailure
    );	

    /**
        @notice Adds a new Attribute to the data domain.
        @dev Caller should be the deployer/owner of the rules engine contract.  An Attribute value can be an optional alternative if it's not a string or numeric.
        @param _attrName    Name/ID of the Attribute
        @param _maxLen      Maximum length of the Attribute (if it is a string)
        @param _maxNumVal   Maximum numeric value of the Attribute (if it is numeric)
        @param _defaultVal  The default value for the Attribute (if one is not found from the source)
        @param _isString    Indicator of whether or not the Attribute is a string
        @param _isNumeric   Indicator of whether or not the Attribute is numeric
    */    
    function addAttribute(bytes32 _attrName, uint _maxLen, uint _maxNumVal, string calldata _defaultVal, bool _isString, bool _isNumeric) external;

    /**
        @notice Adds a new RuleTree.
        @param _owner          Owner/ID of the RuleTree
        @param _ruleTreeName   Name of the RuleTree
        @param _desc           Verbose description of the RuleTree's purpose
    */
    function addRuleTree(address _owner, bytes32 _ruleTreeName, string calldata _desc) external;

    /**
        @notice Adds a new RuleSet onto the hierarchy of a RuleTree.
        @dev RuleSets can have child RuleSets, but they will only be called if the parent's Rules execute to create boolean 'true'.
        @param _owner           Owner/ID of the RuleTree
        @param _ruleSetName     ID/Name of the RuleSet
        @param _desc            Verbose description of the RuleSet
        @param _parentRSName    ID/Name of the parent RuleSet, to which this will be added as a child
        @param _severalFailFlag Indicator of whether or not the RuleSet's execution (as failure) will result in a failure of the RuleTree.  (This flag only applies to leaves in the RuleTree.)
        @param _useAndOp        Indicator of whether or not the rules in the RuleSet will execute with 'AND' between them.  (Otherwise, it will be 'OR'.)
        @param _failQuickFlag   Indicator of whether or not the RuleSet's execution (as failure) should immediately stop the RuleTree.
    */    
    function addRuleSet(address _owner, bytes32 _ruleSetName, string calldata _desc, bytes32 _parentRSName, bool _severalFailFlag, bool _useAndOp, bool _failQuickFlag) external;

    /**
        @notice Adds a new Rule into a RuleSet.
        @dev Rule types can be implemented as any type of action (greater than, less than, etc.)
        @param _owner           Owner/ID of the RuleTree
        @param _ruleSetName     ID/Name of the RuleSet to which the Rule will be added
        @param _ruleName        ID/Name of the Rule being added
        @param _attrName        ID/Name of the Attribute upon which the Rule is invoked
        @param _ruleType        ID of the type of Rule
        @param _rightHandValue  The registered value to be used by the Rule when performing its action upon the Attribute
        @param _notFlag         Indicator of whether or not the NOT operator should be performed on this Rule.
    */    
    function addRule(address _owner, bytes32 _ruleSetName, bytes32 _ruleName, bytes32 _attrName, uint _ruleType, string calldata _rightHandValue, bool _notFlag) external;

    /**
        @notice Executes a RuleTree.
        @param _owner           Owner/ID of the RuleTree
    */
    function executeRuleTree(address _owner) external returns (bool);
    
    /**
        @notice Removes a RuleTree.
        @param _owner           Owner/ID of the RuleTree
    */
    function removeRuleTree(address _owner) external returns (bool);    
}
```

## Rationale

### Attributes

The data points are abstracted in order to let the implementation provide the mechanism for retrieving/populating the data.  Data can be held by an internal data structure, another contract's method, or any number of other options.

### Events

The events specified will help the caller of the RuleTree after execution, so that they may ascertain the navigational flow of RuleSet execution within the RuleTree and so that they may understand which RuleSets failed.

### Right-Hand Value

In the function addRule(), the data type for the right-hand value is 'string' since the rule's action depends on its type, meaning that the value must be provided in a generic form.  In the case of a Rule that performs numerical operations, the provided value could be transformed into a number when stored in the Rule.

## Implementation
- [Wonka](https://github.com/Nethereum/Wonka/tree/master/Solidity/WonkaEngine)

## Security Considerations

The deployer of the contract should be the owner and administrator, allowing for the addition of Attributes and RuleTrees.  Since a RuleTree is owned by a particular EOA (or contract address), the only accounts that should be able to execute the RuleTree should be its owner or the contract's owner/administrator.  If Attributes are defined to exist as data within other contracts, the implementation must take into account the possibility that RuleTree owners must have the security to access the data in those contracts.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

