// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC721Lockable.sol";

/// @title Lockable Extension for ERC721

abstract contract ERC721Lockable is ERC721,IERC721Lockable{


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
     * @dev Public function to set locker. Verifies if the msg.sender is the owner
     * and allows setting locker for tokenid
     */
    function setLocker(uint256 id, address _locker) external virtual override {
        _setLocker(id,_locker);
    }

    /**
     * @dev Private function to set locker. Verifies if the msg.sender is the owner
     * and allows setting locker for tokenid
     */
    function _setLocker(uint256 id, address _locker) private {
        require(msg.sender==ownerOf(id), "ERC721Lockable : Owner Required");
        require(state[id]==State.UNLOCKED, "ERC721Lockable : Locked");
        locker[id]=_locker;
        emit SetLocker(id, _locker);
    }

    /**
     * @dev Public function to remove locker. Verifies if the msg.sender is the owner
     * and allows removal of locker for tokenid if token is unlocked
     */
    function removeLocker(uint256 id) external virtual override {
        _removeLocker(id);
    }

    /**
     * @dev Private function to remove locker. Verifies if the msg.sender is the owner
     * and allows removal of locker for tokenid if token is unlocked
     */
    function _removeLocker(uint256 id) private {
        require(msg.sender==ownerOf(id), "ERC721Lockable : Owner Required");
        require(state[id]==State.UNLOCKED, "ERC721Lockable : Locked");
        delete locker[id];
        emit RemoveLocker(id);
    }

    /**
     * @dev Returns the locker for the tokenId
     *      address(0) means token is not locked
     *      reverts if token does not exist
     */
    function lockerOf(uint256 id) external virtual view override returns(address){
        require(_exists(id), "ERC721Lockable: Nonexistent token");
        return locker[id];
    }

    /**
     * @dev Public function to lock the token. Verifies if the msg.sender is locker
     */
    function lock(uint256 id) external virtual override{
        _lock(id);
    }

    /**
     * @dev Private function to lock the token. Verifies if the msg.sender is locker
     */
    function _lock(uint256 id) private {
        require(msg.sender==locker[id], "ERC721Lockable : Locker Required");
        require(state[id]==State.UNLOCKED, "ERC721Lockable : Locked");
        state[id]=State.LOCKED;
        emit Lock(id);
    }

    /**
     * @dev Public function to unlock the token. Verifies if the msg.sender is locker
     */
    function unlock(uint256 id) external virtual override{
        _unlock(id);
    }

    /**
     * @dev Private function to unlock the token. Verifies if the msg.sender is locker
     */
    function _unlock(uint256 id) private {
        require(msg.sender==locker[id], "ERC721Lockable : Locker Required");
        require(state[id]!=State.LOCKED_APPROVED, "ERC721Lockable : Locked by approved");
        require(state[id]!=State.UNLOCKED, "ERC721Lockable : Unlocked");
        state[id]=State.UNLOCKED;
        emit Unlock(id);
    }

    /**
     * @dev Public function to lock the token. Verifies if the msg.sender is approved
     */
    function lockApproved(uint256 id) external virtual override{
        _lockApproved(id);
    }

    /**
     * @dev Private function to lock the token. Verifies if the msg.sender is approved
     */
    function _lockApproved(uint256 id) internal {
        require(isApprovedForAll(ownerOf(id), msg.sender) || getApproved(id) == msg.sender, "ERC721Lockable : Required approval");
        require(state[id]==State.UNLOCKED, "ERC721Lockable : Locked");
        state[id]=State.LOCKED_APPROVED;
        emit LockApproved(id);    
    }

    /**
     * @dev Public function to unlock the token. Verifies if the msg.sender is approved
     */
    function unlockApproved(uint256 id) external virtual override{
        _unlockApproved(id);
    }

    /**
     * @dev Private function to unlock the token. Verifies if the msg.sender is approved
     */
    function _unlockApproved(uint256 id) internal {
        require(isApprovedForAll(ownerOf(id), msg.sender) || getApproved(id) == msg.sender, "ERC721Lockable : Required approval");
        require(state[id]!=State.LOCKED, "ERC721Lockable : Locked by locker");
        require(state[id]!=State.UNLOCKED, "ERC721Lockable : Unlocked");
        state[id]=State.UNLOCKED;
        emit UnlockApproved(id);
    }

    /*///////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Override approve to make sure token is unlocked
     */
    function approve(address to, uint256 tokenId) public virtual override {
        require (state[tokenId]==State.UNLOCKED, "ERC721Lockable : Locked"); // so the unlocker stays approved
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
            require(state[startTokenId]!=State.LOCKED,"ERC721Lockable : Locked");
            require(state[startTokenId]==State.UNLOCKED || isApprovedForAll(ownerOf(startTokenId), msg.sender) 
            || getApproved(startTokenId) == msg.sender, "ERC721Lockable : Required approval");
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
            interfaceId == type(IERC721Lockable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}