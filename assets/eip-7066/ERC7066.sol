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

    //Mapping from token-id to user address for locking permission
    mapping(uint256 => address) internal locker;
    //Mapping from token-id to state of token
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
    function setLocker(uint256 id, address _locker) public virtual override {
        require(msg.sender==ownerOf(id), "ERC7066 : Owner Required");
        require(state[id]==State.UNLOCKED, "ERC7066 : Locked");
        _setLocker(id,_locker);
    }

    /**
     * @dev Internal function to set locker. 
     */
    function _setLocker(uint256 id, address _locker) internal {
        locker[id]=_locker;
        emit SetLocker(id, _locker);
    }

    /**
     * @dev Public function to remove locker. Verifies if the msg.sender is the owner
     * and allows removal of locker for tokenid if token is unlocked
     */
    function removeLocker(uint256 id) public virtual override {
        require(msg.sender==ownerOf(id), "ERC7066 : Owner Required");
        require(state[id]==State.UNLOCKED, "ERC7066 : Locked");
        _removeLocker(id);
    }

    /**
     * @dev Internal function to remove locker.
     */
    function _removeLocker(uint256 id) internal {
        delete locker[id];
        emit RemoveLocker(id);
    }

    /**
     * @dev Returns the locker for the tokenId
     *      address(0) means token is not locked
     *      reverts if token does not exist
     */
    function lockerOf(uint256 id) public virtual view override returns(address){
        require(_exists(id), "ERC7066: Nonexistent token");
        return locker[id];
    }

    /**
     * @dev Public function to lock the token. Verifies if the msg.sender is locker or approver
     * reverts otherwise
     */
    function lock(uint256 id) public virtual override{
        require(state[id]==State.UNLOCKED, "ERC7066 : Locked");
        if(isApprovedForAll(ownerOf(id), msg.sender) || getApproved(id)== msg.sender){
            lockApprove(id);
        } else if (msg.sender==locker[id]){
            lockLocker(id);
        } else{
            revert("ERC7066: Required locker or approve");
        }
    }

    /**
     * @dev Internal function to lock the token. Verifies if the msg.sender is approved
     */
    function lockApprove(uint256 id) internal {
        state[id]=State.LOCKED_APPROVED;
        emit Lock(id);
    }

    /**
     * @dev Internal function to lock the token. Verifies if the msg.sender is locker
     */
    function lockLocker(uint256 id) internal {
        state[id]=State.LOCKED;
        emit Lock(id);
    }

    /**
     * @dev External function to unlock the token. Verifies the msg.sender is locker or approver
     * reverts otherwise
     */
    function unlock(uint256 id) public virtual override{
        require(state[id]!=State.UNLOCKED, "ERC7066 : Unlocked");
        if(state[id]==State.LOCKED_APPROVED){
            unlockApprove(id);
        }else if(state[id]==State.LOCKED){
            unlockLocker(id);
        }else{
            revert("ERC7066: Required locker or approve");
        }
    }

    /**
     * @dev Internal function to unlock the token. Verifies if the msg.sender is approved
     */
    function unlockApprove(uint256 id) internal{
        require(isApprovedForAll(ownerOf(id), msg.sender) || getApproved(id)== msg.sender,"ERC7066: Approve Required");
        state[id]=State.UNLOCKED;
        emit Unlock(id);
    }

    /**
     * @dev Internal function to unlock the token. Verifies if the msg.sender is locker
     */
    function unlockLocker(uint256 id) internal {
        require(locker[id]==msg.sender,"ERC7066: Locker Required");
        state[id]=State.UNLOCKED;
        emit Unlock(id);
    }

   /**
     * @dev Public function to tranfer and lock the token. Verifies if the msg.sender is locker or approver
     * reverts otherwise
     */
    function transferAndLock(uint256 id, address from, address to, address operator) public virtual override{
        if(isApprovedForAll(ownerOf(id), msg.sender) || getApproved(id) == msg.sender){
            transferApprove(id,from,to,operator);
        }else if(msg.sender==locker[id]){
            transferLocker(id,from,to,operator);
        }else{
            revert("ERC7066: Required locker or approve");
        }
    }

   /**
     * @dev Internal function to tranfer, update locker and lock the token.
     */
    function transferLocker(uint256 id, address from, address to, address operator) internal {
        transferFrom(from, to, id); 
        _setLocker(id,operator);
        lockLocker(id);
    }

    /**
     * @dev Internal function to tranfer, update approve and lock the token.
     */
    function transferApprove(uint256 id, address from, address to, address operator) internal {
        transferFrom(from, to, id); 
        _approve(operator, id);
        lockApprove(id);
    }

    /*///////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Override approve to make sure token is unlocked
     */
    function approve(address to, uint256 tokenId) public virtual override {
        require (state[tokenId]==State.UNLOCKED, "ERC7066 : Locked"); // so the unlocker stays approved
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
            require(state[startTokenId]!=State.LOCKED,"ERC7066 : Locked");
            require(state[startTokenId]==State.UNLOCKED || isApprovedForAll(ownerOf(startTokenId), msg.sender) 
            || getApproved(startTokenId) == msg.sender, "ERC7066 : Required approval");
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