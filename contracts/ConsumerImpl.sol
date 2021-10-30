//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./IERC721Consumer.sol";

contract ConsumerImpl is IERC721Consumer, ERC721 {

    mapping (uint256 => address) consumers;

    constructor() ERC721("ReferenceImpl", "RIMPL") {
    }

    function consumerOf(uint256 _tokenId) view external returns (address) {
        return consumers[_tokenId];
    }

    function changeConsumer(address _newConsumer, uint256 _tokenId) external {
        require(msg.sender == this.ownerOf(_tokenId), "IERC721Consumer: caller is not owner nor approved");

        address previousConsumer = consumers[_tokenId];
        consumers[_tokenId] = _newConsumer;
        emit ConsumerChanged(previousConsumer, _newConsumer);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Consumer).interfaceId || super.supportsInterface(interfaceId);
    }
}