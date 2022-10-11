// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "../factory/IERC5058Factory.sol";
import "../factory/IERC721Bound.sol";
import "../ERC5058.sol";

abstract contract ERC5058Bound is ERC5058 {
    address public bound;

    function _setFactory(address _factory) internal {
        bound = IERC5058Factory(_factory).boundOf(address(this));
    }

    function _setBoundBaseTokenURI(string memory uri) internal {
        IERC721Bound(bound).setBaseTokenURI(uri);
    }

    function _setBoundContractURI(string memory uri) internal {
        IERC721Bound(bound).setContractURI(uri);
    }

    function burnBound(uint256 tokenId) external {
        IERC721Bound(bound).burn(tokenId);
    }

    // NOTE:
    //
    // this will be called when `lock` or `unlock`
    function _afterTokenLock(
        address operator,
        address from,
        uint256 tokenId,
        uint256 expired
    ) internal virtual override {
        super._afterTokenLock(operator, from, tokenId, expired);

        if (bound != address(0)) {
            if (expired != 0) {
                // lock mint
                if (operator != address(0)) {
                    IERC721Bound(bound).safeMint(msg.sender, tokenId, "");
                }
            } else {
                // unlock
                if (IERC721Bound(bound).exists(tokenId)) {
                    IERC721Bound(bound).burn(tokenId);
                }
            }
        }
    }
}
