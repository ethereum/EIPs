//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC721Consumer.sol";

contract ConsumerImpl is IERC721Consumer, ERC721 {

    // Mapping from token ID to consumer address
    mapping (uint256 => address) _tokenConsumers;

    constructor() ERC721("ReferenceImpl", "RIMPL") {
    }

    /**
     * @dev See {IERC721Consumer-consumerOf}
     */
    function consumerOf(uint256 _tokenId) view external returns (address) {
        require(_exists(_tokenId), "ERC721Consumer: consumer query for nonexistent token");
        return _tokenConsumers[_tokenId];
    }

    /**
     * @dev See {IERC721Consumer-changeConsumer}
     */
    function changeConsumer(address _consumer, uint256 _tokenId) external {
        address owner = this.ownerOf(_tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721Consumer: changeConsumer caller is not owner nor approved for all");

        _tokenConsumers[_tokenId] = _consumer;
        emit ConsumerChanged(owner, _consumer, _tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Consumer).interfaceId || super.supportsInterface(interfaceId);
    }
}