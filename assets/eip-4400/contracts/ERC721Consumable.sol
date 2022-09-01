// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC721Consumable.sol";

contract ERC721Consumable is IERC721Consumable, ERC721 {

    // Mapping from token ID to consumer address
    mapping(uint256 => address) _tokenConsumers;

    constructor (string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    /**
     * @dev Returns true if the `msg.sender` is approved, owner or consumer of the `tokenId`
     */
    function _isApprovedOwnerOrConsumer(uint256 tokenId) internal view returns (bool) {
        return _isApprovedOrOwner(msg.sender, tokenId) || _tokenConsumers[tokenId] == msg.sender;
    }

    /**
     * @dev See {IERC721Consumable-consumerOf}
     */
    function consumerOf(uint256 _tokenId) view external returns (address) {
        require(_exists(_tokenId), "ERC721Consumable: consumer query for nonexistent token");
        return _tokenConsumers[_tokenId];
    }

    /**
     * @dev See {IERC721Consumable-changeConsumer}
     */
    function changeConsumer(address _consumer, uint256 _tokenId) external {
        address owner = this.ownerOf(_tokenId);
        require(msg.sender == owner || msg.sender == getApproved(_tokenId) || isApprovedForAll(owner, msg.sender),
            "ERC721Consumable: changeConsumer caller is not owner nor approved");
        _changeConsumer(owner, _consumer, _tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Consumable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override (ERC721) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
        _changeConsumer(_from, address(0), _tokenId);
    }

    /**
     * @dev Changes the consumer
     * Requirement: `tokenId` must exist
     */
    function _changeConsumer(address _owner, address _consumer, uint256 _tokenId) internal {
        _tokenConsumers[_tokenId] = _consumer;
        emit ConsumerChanged(_owner, _consumer, _tokenId);
    }
}
