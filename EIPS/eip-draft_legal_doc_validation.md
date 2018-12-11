---
eip: <to be assigned>
title: A document management proposal for legally binding token
author: Tony Guan <tony.kuan@hotmail.com>
status: Draft
type: Standards Track
category: ERC
created: 2018-12-05
requires (*optional): <EIP number(s)>
replaces (*optional): <EIP number(s)>
---

# Standard for adding legal contract into token smart contract 

## Simple Summary
Proposing a model for including verified legal contracts into token. The purpose is to ensure that token is legally binding and relevant parties’ rights and obligations are enforceable by law. 

## Abstract
In order to make token legally binding, legal documents must be attached to token smart contract and serve as the foundation for judicial purpose. More importantly, documents must be carefully validated before it goes on chain. This proposal adopts multi-signature validation mechanism to ensure a legal contract is agreed by all relevant parties (granter, beneficiary, code auditor, lawyer) before it can be added to token smart contract. The use cases include day-to-day business activies where paper contracts come into play. In addition, the proposal provides role management functionality to authorize addresses that can sign as a specific role. 


## Motivation
This is the first step of a bigger goal: to establish a legal-oriented token system which ensures rights of token holders are protected by law. 

The essence of blockchain is forging consensus and trust. Token, in its current form, ensures trust with solidity code. However, a smart contract is not a legally binding contract. Imagine if two parties enter into agreement and put it into smart contract code. Say if there are some loopholes in the code that allow one party to default, how do the other party protect his/her rights? By showing the smart contract code to the court? 

The eventual ideal state would be “Code is Law”, meaning whatever written in code would be recognized and protected by law. However, in the foreseeable future, law enforcement has to rely on documents rather than code. It is unreasonable to expect the court judges to make a ruling based on some programs written in solidity. Therefore, it’s crucial to embed in the token the legal contracts that specifies the rights and obligations of relevant parties. Once the contract is validated and added to the smart contract, relevant token holders would be able to access and use it as evidence to claim legal protection in case anything goes wrong with the smart contract. Such "legally binding token" would have both computer programs and traditional judicial contracts as the foundation of trust. 

Nonetheless, we are missing a standard for managing legal documents. Some token standards (such as ERC 721) allows to add file links (http or ipfs) stored as metadata. However, existing solutions do not verify the validity of the document links added to the blockchain. Legal documents are an essential piece of security token. Its validity needs to be carefully examined before it goes on chain. That’s why this proposal introduces multi-signature validation mechanism to ensure a legal contract is agreed by all relevant parties before it is added to security token smart contract as metadata.

In common business situations, signing a contract involves three different parties: granter, beneficiary and lawyer. For example, in the case of a company that wants to issue incentive stock options to an employee, the company would be the granter and the employee would be the beneficiary. In addition, contracts should have been drafted by the lawyer who needs to ensure the legality of the process.

However, translating documents into smart contract code is a crucial gap between the blockchain world and the real world. We need someone to testify what’s written in code is consistent with what’s written in the contract document. That’s why we introduce the code auditor role. Code auditors’ responsibilities include guaranteeing the fairness and consistency of the smart contract with their specialty and reputation.


Below is an overview of the process.

![alt text][flowchart]

[flowchart]: https://github.com/xguan5/Legally-Binding-Token/blob/master/FlowChart.png "Logo Title Text 2"


With a document management standard in place, token rights will be enforceable both by legal enforcement of rights and obligations as well as via tamper-proof execution of computer code. The use cases of asset tokenization can potentially be extended to a much broader setting - whereever paper contracts are involved. 


## Specification

### Role Management
There are four different roles involved in legal contracts: granter, beneficiary, lawyer and code auditor. Their respective descriptions were provided in the previous motivation section. 

Among the four roles, granter has some special rights over the others. A granter can control if an address can be authorized or renounced as a specific role. Users should carefully validate the addresses for each role. The identity verification is beyond the scope of this project.

Each role has its own contract for adding/deleting actions etc. Role contract import openzeppelin's Roles.sol. Below is an exmaple of granter interface. The other three roles have more or less same functions.

```
contract GranterRole {
  using Roles for Roles.Role; // use openzeppline's Roles.sol

  event GranterAdded(address indexed account);
  event GranterRemoved(address indexed account);

  Roles.Role private granters;

  constructor() public;

  modifier onlyGranter();

  //check if an address is authorized as granter
  function isGranter(address account) public view returns (bool);

  //authorize an address as granter
  function addGranter(address account) public onlyGranter;

  function renounceGranter(address account) public onlyGranter ;

  function _addGranter(address account) internal;

  function _removeGranter(address account) internal;
}

```

### Document Management
 
Document contract extends from the role contracts. It manage a list of documents including each document' signer addresses and signing status for each role.

#### AddDocument

````
function addDocument(bytes32 docHash, address _granter, address _lawyer, address _codeAudit, address _beneficiary) public preAuthorized(_granter,_lawyer,_codeAudit,_beneficiary) onlyGranter returns (bool success);
````

Granter add a document to sign by providing a IPFS hash (in bytes32 document) pointing to the document and also the four addresses as four roles that need to confirm this document. The four addresses provided must be pre-authorized as each respective role in their role contract. 

Only granter has the authority to perform this action. When this function is called, granter confirmation is assumed.

Must emit a DocumentAdd event and GranterConfirmation event.

Documents' IPFS hash is stored as bytes32 for efficiency purpose. Currently IPFS hash is 34 bytes long with first two segments represented as a single byte (uint8). We could use Multihash structure to convert the 34 bytes IPFS hash to 32 bytes. More details can be found at [https://github.com/saurfang/ipfs-multihash-on-solidity].


#### ConfirmDocument

````

function confirmDocument(bytes32 docHash) public returns (bool success);
````

After granter add a document to sign, the specified signers each reviews the document and calls confirmDocument function to provide their respective confirmations.
Must emit respective role's confirmation event.

#### SubmitDocument

````

function submitDocument(bytes32 docHash) allSigned(docHash) public returns (bool success);
````

Once all confirmations are obtained, this document status can be labeled as submitted and pushed into a list of submitted documents.
Only granter can perform this action. Must emit DocumentSubmit event.

#### RevokeConfirmation

````

function revokeConfirmation(bytes32 docHash) public returns (bool success);
````
Each signer can revoke their confirmation before document is submitted. After document is submitted, confirmation cannot be revoked. Must emit respective role's Revocation event.

#### isDoc
````

function isDoc(bytes32 docHash) public constant returns (bool isIndeed);
````
Check if the provided document hash exists in the submitted document array.

#### getAllDocument
````

function getAllDocument() public view returns (bytes32[] docHashes);
````
Returns an array of all submitted document hashes.

#### getDocStatus
````

function getDocStatus(bytes32 docHash) public constant returns(address granter, address lawyer, address codeAudit, address beneficiary, bool granterSigned, bool lawyerSigned, bool codeAuditSigned, bool beneficiarySigned);
````
Check the status of the provided document hash. Returns its signer addresses and each signer's status.

#### Interface

````

contract Document is GranterRole, LawyerRole, CodeAuditorRole, BeneficiaryRole {


	struct DocStruct {
		address granter;
		address lawyer;
		address codeAudit;
		address beneficiary;
		bool granterSigned;
		bool lawyerSigned;
		bool codeAuditSigned;
		bool beneficiarySigned;
		bool submitted;
		uint index;
	}

	bytes32[] docIndex; //list of doc keys (docHash)


	//use docHash as key to map to DocStruct
	mapping (bytes32 => DocStruct) public DocStructs;

	event DocumentAdd(bytes32 indexed docHash);
	event DocumentSubmit(bytes32 indexed docHash);
	event LawyerRevocation(address indexed sender, bytes32 indexed docHash);
	event BeneficiaryRevocation(address indexed sender, bytes32 indexed docHash);
	event GranterRevocation(address indexed sender, bytes32 indexed docHash);
	event CodeAuditRevocation(address indexed sender, bytes32 indexed docHash);
	event LawyerConfirmation(address indexed sender, bytes32 indexed docHash);
	event BeneficiaryConfirmation(address indexed sender, bytes32 indexed docHash);
	event GranterConfirmation(address indexed sender, bytes32 indexed docHash);
	event CodeAuditConfirmation(address indexed sender, bytes32 indexed docHash);

	modifier allSigned(bytes32 docHash);

	modifier preAuthorized(address granter, address lawyer, address codeAudit, address beneficiary);

	function addDocument(bytes32 docHash, address _granter, address _lawyer, address _codeAudit, address _beneficiary) public preAuthorized(_granter,_lawyer,_codeAudit,_beneficiary) onlyGranter returns (bool success);

	//owner(Granter) add a new document hash, needs confirmation from all requiredparties
	function submitDocument(bytes32 docHash) allSigned(docHash) public returns (bool success);

	//relevant party review and confirm
	function confirmDocument(bytes32 docHash) public returns (bool success);

	function revokeConfirmation(bytes32 docHash) public returns (bool success);

	function isDoc(bytes32 docHash) public constant returns (bool isIndeed);

	function getAllDocument() public view returns (bytes32[] docHashes);

	function countAllDocument() public view returns (uint count);

	function getDocAtIndex(uint index) public constant returns(bytes32 docHash);

	function getDocStatus(bytes32 docHash) public constant returns(address granter, address lawyer, address codeAudit, address beneficiary, bool granterSigned, bool lawyerSigned, bool codeAuditSigned, bool beneficiarySigned);

	//make sure none of the 4 address are the same
	function compAddress(address _a, address _b, address _c, address _d) internal pure returns (bool success);

}
````


## Rationale

### Current Limitation
The design of this project was motivated by the frustration of bringing more "private" asset on chain. Existing solutions do not satisfy situations where paper contracts are needed as the foundation of trust. Simply attaching a file url as metadata does not suffice as its validity cannot be guaranteed. Careful validation is needed before document can be added to token. That is the purpose of this project. 

## Backward Compatibility
This proposal is compatible with popular token standards. Token issuers can include the document management functionalities by inheriting from this proposal.

## Test Cases
Sample test cases can be found [here](https://github.com/xguan5/Legally-Binding-Token/tree/master/test)

## Implementation
A sample implementation can be found [here](https://github.com/xguan5/Legally-Binding-Token/tree/master/contracts)




