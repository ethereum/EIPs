// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ERC6150.sol";
import "./interfaces/IERC6150ParentTransferable.sol";

abstract contract ERC6150ParentTransferable is
    ERC6150,
    IERC6150ParentTransferable
{
    function transferParent(
        uint256 newParentId,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC6150ParentTransferable: caller is not token owner nor approved"
        );
        if (newParentId != 0) {
            require(
                _exists(newParentId),
                "ERC6150ParentTransferable: newParentId doesn't exists"
            );
        }

        address owner = ownerOf(tokenId);
        uint256 oldParentId = parentOf(tokenId);
        _safeBurn(tokenId);
        _safeMintWithParent(owner, newParentId, tokenId);
        emit ParentTransferred(tokenId, oldParentId, newParentId);
    }

    function batchTransferParent(
        uint256 newParentId,
        uint256[] memory tokenIds
    ) public virtual override {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            transferParent(tokenIds[i], newParentId);
        }
    }
}
