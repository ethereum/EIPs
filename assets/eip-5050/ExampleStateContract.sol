// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import {ERC5050State, Action} from "./ERC5050State.sol";
import {ERC5050, Action} from "./ERC5050.sol";

struct TokenInfo {
   uint256 health;
   uint256 healthRemaining;
   uint256 power;
   uint256 blockedAt;
   uint256 blockPower;
   uint256 lockedUntilBlock;
   uint256 wins;
   bool hasRegistered;
}

interface IFightGame {
     function getStats(address _contract, uint256 _tokenId) external view returns (TokenInfo);
}

contract FightGame is IFightGame, ERC5050State {
    
    bytes4 constant LIGHT_ATTACK_SELECTOR = bytes4(keccak256("fg.light-attack"));
    bytes4 constant HEAVY_ATTACK_SELECTOR = bytes4(keccak256("fg.heavy-attack"));
    bytes4 constant BLOCK_SELECTOR = bytes4(keccak256("fg.block"));
    
    uint256 constant BLOCK_DECAY = 100;
    uint256 constant LIGHT_ATTACK_DECAY = 200;
    uint256 constant HEAVY_ATTACK_DECAY = 500;
    
    mapping(address => mapping(uint256 => TokenInfo)) state;
    
    constructor()  {
        _registerReceivable("fg.light-attack");
        _registerReceivable("fg.heavy-attack");
        _registerReceivable("fg.block");
    }
    
    function register(address _contract, uint256 _tokenId) external {
        require(msg.sender == ownerOf(_contract, _tokenId), "sender not token owner");
        require(!state[_contract][_tokenId].hasRegistered, "token already registered");
        state[_contract][_tokenId] = TokenInfo(100, 100, 5, 0, 0, 0, true);
    }
    
    function getStats(address _contract, uint256 _tokenId) external view returns (TokenInfo){
        return state[_contract][_tokenId];
    }
    
    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {
        TokenInfo storage from = state[action.from._address][action.from._tokenId];
        require(from.healthRemaining > 0, "health 0");
        require(block.number > from.lockedUntilBlock, "token locked");
        if (action.selector == BLOCK_SELECTOR) {
            from.blockPower = from.power * 3;
            from.blockedAt = block.number;
            from.lockedUntilBlock = block.number + BLOCK_DECAY;
            return;
        }
        
        TokenInfo storage to = state[action.to._address][action.to._tokenId];
        require(to.healthRemaining > 0, "target health 0");
        
        uint256 damage;
        if (action.selector == LIGHT_ATTACK_SELECTOR ) {
            damage = from.power;
            from.lockedUntilBlock = block.number + LIGHT_ATTACK_DECAY;
        }
        
        if (action.selector == HEAVY_ATTACK_SELECTOR) {
            damage = from.power * 3;
            from.lockedUntilBlock = block.number + HEAVY_ATTACK_DECAY;
        }
        if(to.blockedAt + BLOCK_DECAY > block.number) {
            if(to.blockPower >= damage){
                to.blockPower -= damage;
                return;
            }
            damage -= to.blockPower;
        }
        if(to.healthRemaining > damage){
            to.healthRemaining -= damage;
            return;
        }
        
        // Winner gains loser's power and some health 
        from.power += to.power;
        from.healthRemaining += to.power;
        from.wins++;
        to.healthRemaining = 0;
    }
}

contract Fighter is ERC5050, ERC721 {
    
    IFightGame stateContract;
    
    constructor(address _stateContract)  {
        _registerAction("fg.light-attack");
        _registerAction("fg.heavy-attack");
        _registerSendable("fg.block");
        stateContract = IFightGame(_stateContract);
    }
    
    // Update NFT render / metadata based on game stats
    function tokenURICharacterEmoji(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        TokenInfo memory stats = stateContract.getStats(address(this), tokenId);
        if(stats.healthRemaining == 0){
            return unicode"😵";
        }
        if(stats.power > 100){
            return unicode"🦾";
        }
        if(stats.power > 50){
            return unicode"💪";
        }
        if(stats.power > 20){
            return unicode"🤩";
        }
        if(stats.power > 5){
            return unicode"😃";
        }
        return unicode"😀";
    }
}