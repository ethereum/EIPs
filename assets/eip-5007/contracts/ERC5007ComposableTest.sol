// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ERC5007Composable.sol";

contract ERC5007ComposableTest is ERC5007Composable  {

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    /// @notice mint a new root time NFT
    /// @param to_  The owner of the new token
    /// @param id_  The id of the new token
    /// @param startTime_  The start time of the new token
    /// @param endTime_  The end time of the new token
    function mint(
        address to_,
        uint256 id_,
        uint64 startTime_,
        uint64 endTime_
    ) public {
        super._mintTimeNft(to_, id_, startTime_, endTime_);
    }

    /**
     * @dev Returns the interfaceId of IERC5007Composable.
     */
    function getInterfaceId() public pure returns (bytes4) {
        return type(IERC5007Composable).interfaceId;
    }    
}
