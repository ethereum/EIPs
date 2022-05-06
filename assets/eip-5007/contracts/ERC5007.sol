// SPDX-License-Identifier: CC0
pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC5007.sol";

contract ERC5007 is ERC721, IERC5007  {

    struct TimeNftInfo {
        uint64 startTime;
        uint64 endTime; 
    }

    mapping(uint256 /* tokenId */ => TimeNftInfo) internal _timeNftMapping;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_){
    }

    /// @notice Get the start time of the token
    /// @dev Throws if `tokenId` is not valid token
    /// @param tokenId  The tokenId of the token
    /// @return The start time of the token
    function startTime(uint256 tokenId) public view virtual override returns (uint64) {
        require(_exists(tokenId),"invalid tokenId");
        return _timeNftMapping[tokenId].startTime;
    }
    
    /// @notice Get the end time of the token
    /// @dev Throws if `tokenId` is not valid token
    /// @param tokenId  The tokenId of the token
    /// @return The end time of the token
    function endTime(uint256 tokenId) public view virtual override returns (uint64) {
        require(_exists(tokenId),"invalid tokenId");
        return _timeNftMapping[tokenId].endTime;
    }


    /// @notice mint a new time NFT
    /// @param to_  The owner of the new token
    /// @param id_  The id of the new token
    /// @param startTime_  The start time of the new token
    /// @param endTime_  The end time of the new token
    function _mintTimeNft(address to_, uint256 id_, uint64 startTime_, uint64 endTime_) internal virtual  {
        _mint(to_, id_);

        TimeNftInfo storage info = _timeNftMapping[id_];
        info.startTime = startTime_;
        info.endTime = endTime_;
    }


    /// @notice burn a time NFT
    /// @param tokenId  The id of the token
    function _burn(uint256 tokenId) internal  virtual override{
        super._burn(tokenId);
        delete _timeNftMapping[tokenId];
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC5007).interfaceId || super.supportsInterface(interfaceId);
    }
}
