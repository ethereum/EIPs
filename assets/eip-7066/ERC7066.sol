// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC7066.sol";

/// @title Lockable Extension for ERC721
/// @dev Implementation for the Lockable extension
/// @author StreamNFT 

abstract contract ERC7066 is ERC721,IERC7066{


    /*///////////////////////////////////////////////////////////////
                            LOCKABLE EXTENSION STORAGE                        
    //////////////////////////////////////////////////////////////*/

    //Mapping from token id to user address for locking permission
    mapping(uint256 => address) internal locker;
    //Mapping from token id to state of token
    mapping(uint256 => State) internal state;
    //Possible states of a token
    enum State{UNLOCKED,LOCKED,LOCKED_APPROVED}

    /*///////////////////////////////////////////////////////////////
                              LOCKABLE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev External function to set locker. Verifies if the msg.sender is the owner
     * and allows setting locker for tokenid
     */
    function setLocker(uint256 id, address _locker) external virtual override {
        require(msg.sender==ownerOf(id), "ERC7066 : Owner Required");
        require(state[id]==State.UNLOCKED, "ERC7066 : Locked");
        _setLocker(id,_locker);
    }

    /**
     * @dev Internal function to set locker. Verifies if the msg.sender is the owner
     * and allows setting locker for tokenid
     */
    function _setLocker(uint256 id, address _locker) internal {
        locker[id]=_locker;
        emit SetLocker(id, _locker);
    }

    /**
     * @dev External function to remove locker. Verifies if the msg.sender is the owner
     * and allows removal of locker for tokenid if token is unlocked
     */
    function removeLocker(uint256 id) external virtual override {
        require(msg.sender==ownerOf(id), "ERC7066 : Owner Required");
        require(state[id]==State.UNLOCKED, "ERC7066 : Locked");
        _removeLocker(id);
    }

    /**
     * @dev Internal function to remove locker. Verifies if the msg.sender is the owner
     * and allows removal of locker for tokenid if token is unlocked
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
    function lockerOf(uint256 id) external virtual view override returns(address){
        require(_exists(id), "ERC7066: Nonexistent token");
        return locker[id];
    }

    /**
     * @dev Public function to lock the token. Verifies if the msg.sender is locker
     */
    function lock(uint256 id) external virtual override{
        require(msg.sender==locker[id], "ERC7066 : Locker Required");
        require(state[id]==State.UNLOCKED, "ERC7066 : Locked");
        _lock(id);
    }

    /**
     * @dev Internal function to lock the token. Verifies if the msg.sender is locker
     */
    function _lock(uint256 id) internal {
        state[id]=State.LOCKED;
        emit Lock(id);
    }

    /**
     * @dev External function to unlock the token. Verifies if the msg.sender is locker
     */
    function unlock(uint256 id) external virtual override{
        require(msg.sender==locker[id], "ERC7066 : Locker Required");
        require(state[id]!=State.LOCKED_APPROVED, "ERC7066 : Locked by approved");
        require(state[id]!=State.UNLOCKED, "ERC7066 : Unlocked");
        _unlock(id);
    }

    /**
     * @dev Internal function to unlock the token. Verifies if the msg.sender is locker
     */
    function _unlock(uint256 id) internal {
        state[id]=State.UNLOCKED;
        emit Unlock(id);
    }

    /**
     * @dev Public function to lock the token. Verifies if the msg.sender is approved
     */
    function lockApproved(uint256 id) external virtual override{
        require(isApprovedForAll(ownerOf(id), msg.sender) || getApproved(id) == msg.sender, "ERC7066 : Required approval");
        require(state[id]==State.UNLOCKED, "ERC7066 : Locked");
        _lockApproved(id);
    }

    /**
     * @dev Internal function to lock the token. Verifies if the msg.sender is approved
     */
    function _lockApproved(uint256 id) internal  {
        state[id]=State.LOCKED_APPROVED;
        emit LockApproved(id);    
    }

    /**
     * @dev External function to unlock the token. Verifies if the msg.sender is approved
     */
    function unlockApproved(uint256 id) external virtual override{
        require(isApprovedForAll(ownerOf(id), msg.sender) || getApproved(id) == msg.sender, "ERC7066 : Required approval");
        require(state[id]!=State.LOCKED, "ERC7066 : Locked by locker");
        require(state[id]!=State.UNLOCKED, "ERC7066 : Unlocked");
        _unlockApproved(id);
    }

    /**
     * @dev Internal function to unlock the token. Verifies if the msg.sender is approved
     */
    function _unlockApproved(uint256 id) internal{
        state[id]=State.UNLOCKED;
        emit UnlockApproved(id);
    }

   /**
     * @dev External function to tranfer and update locker for the token. Verifies if the msg.sender is owner
     */
    function transferWithLock(uint256 id, address from, address to, address _locker) external virtual override{
        _transferWithLock(id,from,to,_locker);
    }

   /**
     * @dev Internal function to tranfer and update locker for the token. Verifies if the msg.sender is owner
     */
    function _transferWithLock(uint256 id, address from, address to, address _locker) internal {
        transferFrom(from, to, id); 
        _setLocker(id,_locker);
    }

    /**
     * @dev External function to tranfer, update locker and approve locker for the token. Verifies if the msg.sender is owner
     */
    function transferWithApprove(uint256 id, address from, address to, address _approved) external virtual override{
        _transferWithApprove(id,from,to,_approved);
    }

    /**
     * @dev Internal function to tranfer, update locker and approve locker for the token. Verifies if the msg.sender is owner
     */
    function _transferWithApprove(uint256 id, address from, address to, address _approved) internal {
        transferFrom(from, to, id); 
        _approve(_approved, id);
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