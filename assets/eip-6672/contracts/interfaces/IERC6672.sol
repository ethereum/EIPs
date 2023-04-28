// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC6672 is IERC721 {
    event Redeem(
        address indexed _operator,
        uint256 indexed _tokenId,
        address redeemer,
        bytes32 _redemptionId,
        string _memo
    );

    event Cancel(
        address indexed _operator,
        uint256 indexed _tokenId,
        bytes32 _redemptionId,
        string _memo
    );

    function isRedeemed(
        address _operator,
        bytes32 _redemptionId,
        uint256 _tokenId
    ) external view returns (bool);

    function getRedemptionIds(
        address _operator,
        uint256 _tokenId
    ) external view returns (bytes32[] memory);

    function redeem(
        bytes32 _redemptionId,
        uint256 _tokenId,
        string memory _memo
    ) external;

    function cancel(
        bytes32 _redemptionId,
        uint256 _tokenId,
        string memory _memo
    ) external;
}