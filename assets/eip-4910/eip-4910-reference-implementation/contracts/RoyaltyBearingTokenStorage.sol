// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import './StorageStructure.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import './RoyaltyModule.sol';
import './PaymentModule.sol';

contract RoyaltyBearingTokenStorage is StorageStructure, AccessControlEnumerable {
    using Address for address;
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 public constant CREATOR_ROLE = keccak256('CREATOR_ROLE');
    string internal _baseTokenURI;
    Counters.Counter internal _tokenIdTracker;

    mapping(uint256 => Child) internal ancestry; //An ancestry mapping of the parent-to-child NFT relationship
    mapping(string => address) internal allowedToken; //A mapping of supported token types to their origin contracts
    mapping(address => uint256) internal allowedTokenContract; //A mapping of supported token types to their origin contracts
    address[] internal allowedTokenList;
    mapping(bytes4 => bool) internal functionSigMap; //functionSig mapping

    RoyaltyModule internal royaltyModule;
    PaymentModule internal paymentModule;
    //address internal logicModule;

    uint256 internal _numGenerations;
    address internal _ttAddress;
    uint256 internal _royaltySplitTT;

    event Received(address sender, uint256 amount, uint256 tokenId);
}
