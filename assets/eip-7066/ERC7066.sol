// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC7066.sol";

/// @title ERC7066: Lockable Extension for ERC721
/// @dev Implementation for the Lockable extension ERC7066 for ERC721
/// @author StreamNFT 

abstract contract ERC7066 is ERC721,IERC7066{


    /*///////////////////////////////////////////////////////////////
                            ERC7066 EXTENSION STORAGE                        
    //////////////////////////////////////////////////////////////*/

    //Mapping from tokenId to user address for locking permission
    mapping(uint256 => address) internal locker;
    //Mapping from tokenId to state of token
    mapping(uint256 => State) internal state;
    //Possible states of a token
    enum State{UNLOCKED,LOCKED,LOCKED_APPROVED}

    /*///////////////////////////////////////////////////////////////
                              ERC7066 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Public function to set locker. Verifies if the msg.sender is the owner
     * and allows setting locker for tokenid
     */
    function setLocker(uint256 tokenId, address _locker) public virtual override {
        require(msg.sender==ownerOf(tokenId), "ERC7066: Required Owner");
        require(state[tokenId]==State.UNLOCKED, "ERC7066: Locked");
        _setLocker(tokenId,_locker);
    }

    /**
     * @dev Internal function to set locker. 
     */
    function _setLocker(uint256 tokenId, address _locker) internal {
        locker[tokenId]=_locker;
        emit SetLocker(tokenId, _locker);
    }

    /**
     * @dev Public function to remove locker. Verifies if the msg.sender is the owner
     * and allows removal of locker for tokenid if token is unlocked
     */
    function removeLocker(uint256 tokenId) public virtual override {
        require(msg.sender==ownerOf(tokenId), "ERC7066: Required Owner");
        require(state[tokenId]==State.UNLOCKED, "ERC7066: Locked");
        _removeLocker(tokenId);
    }

    /**
     * @dev Internal function to remove locker.
     */
    function _removeLocker(uint256 tokenId) internal {
        delete locker[tokenId];
        emit RemoveLocker(tokenId);
    }

    /**
     * @dev Returns the locker for the tokenId
     *      address(0) means token is not locked
     *      reverts if token does not exist
     */
    function lockerOf(uint256 tokenId) public virtual view override returns(address){
        require(_exists(tokenId), "ERC7066: Nonexistent token");
        return locker[tokenId];
    }

    /**
     * @dev Public function to lock the token. Verifies if the msg.sender is locker or approver
     * reverts otherwise
     */
    function lock(uint256 tokenId) public virtual override{
        require(state[tokenId]==State.UNLOCKED, "ERC7066: Locked");
        if(isApprovedForAll(ownerOf(tokenId), msg.sender) || getApproved(tokenId)== msg.sender){
            lockApprove(tokenId);
        } else if (msg.sender==locker[tokenId]){
            lockLocker(tokenId);
        } else{
            revert("ERC7066: Required locker or approve");
        }
    }

    /**
     * @dev Internal function to lock the token. Verifies if the msg.sender is approved
     */
    function lockApprove(uint256 tokenId) internal {
        state[tokenId]=State.LOCKED_APPROVED;
        emit Lock(tokenId);
    }

    /**
     * @dev Internal function to lock the token. Verifies if the msg.sender is locker
     */
    function lockLocker(uint256 tokenId) internal {
        state[tokenId]=State.LOCKED;
        emit Lock(tokenId);
    }

    /**
     * @dev External function to unlock the token. Verifies the msg.sender is locker or approver
     * reverts otherwise
     */
    function unlock(uint256 tokenId) public virtual override{
        require(state[tokenId]!=State.UNLOCKED, "ERC7066: Unlocked");
        if(state[tokenId]==State.LOCKED_APPROVED){
            unlockApprove(tokenId);
        }else if(state[tokenId]==State.LOCKED){
            unlockLocker(tokenId);
        }else{
            revert("ERC7066: Required locker or approve");
        }
    }

    /**
     * @dev Internal function to unlock the token. Verifies if the msg.sender is approved
     */
    function unlockApprove(uint256 tokenId) internal{
        require(isApprovedForAll(ownerOf(tokenId), msg.sender) || getApproved(tokenId)== msg.sender,"ERC7066: Required Approve");
        state[tokenId]=State.UNLOCKED;
        emit Unlock(tokenId);
    }

    /**
     * @dev Internal function to unlock the token. Verifies if the msg.sender is locker
     */
    function unlockLocker(uint256 tokenId) internal {
        require(locker[tokenId]==msg.sender,"ERC7066: Required Locker");
        state[tokenId]=State.UNLOCKED;
        emit Unlock(tokenId);
    }

   /**
     * @dev Public function to tranfer and lock the token. Verifies if the msg.sender is locker or approver
     * reverts otherwise
     */
    function transferAndLock(uint256 tokenId, address from, address to, address operator) public virtual override{
        if(isApprovedForAll(ownerOf(tokenId), msg.sender) || getApproved(tokenId) == msg.sender){
            transferApprove(tokenId,from,to,operator);
        }else if(msg.sender==locker[tokenId]){
            transferLocker(tokenId,from,to,operator);
        }else{
            revert("ERC7066: Required locker or approve");
        }
    }

   /**
     * @dev Internal function to tranfer, update locker and lock the token.
     */
    function transferLocker(uint256 tokenId, address from, address to, address operator) internal {
        transferFrom(from, to, tokenId); 
        _setLocker(tokenId,operator);
        lockLocker(tokenId);
    }

    /**
     * @dev Internal function to tranfer, update approve and lock the token.
     */
    function transferApprove(uint256 tokenId, address from, address to, address operator) internal {
        transferFrom(from, to, tokenId); 
        _approve(operator, tokenId);
        lockApprove(tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Override approve to make sure token is unlocked
     */
    function approve(address to, uint256 tokenId) public virtual override {
        require (state[tokenId]==State.UNLOCKED, "ERC7066: Locked"); // so the unlocker stays approved
        super.approve(to, tokenId);
    }

    /**
     * @dev Override _beforeTokenTransfer to make sure token is unlocked or msg.sender is approved if 
     * token is lockApproved
     */
    function _beforeTokenTransfer( 
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        // if it is a Transfer or Burn, we always deal with one token, that is startTokenId
        if (from != address(0)) { 
            require(state[startTokenId]!=State.LOCKED,"ERC7066: Locked");
            require(state[startTokenId]==State.UNLOCKED || isApprovedForAll(ownerOf(startTokenId), msg.sender) 
            || getApproved(startTokenId) == msg.sender, "ERC7066: Required Approved");
        }
        super._beforeTokenTransfer(from,to,startTokenId,quantity);
    }

    /**
     * @dev Override _afterTokenTransfer to make locker is purged
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        // if it is a Transfer or Burn, we always deal with one token, that is startTokenId
        if (from != address(0)) { 
            state[startTokenId]==State.UNLOCKED;
            delete locker[startTokenId];
        }
        super._afterTokenTransfer(from,to,startTokenId,quantity);
    }

     /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
         return
            interfaceId == type(IERC7066).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}