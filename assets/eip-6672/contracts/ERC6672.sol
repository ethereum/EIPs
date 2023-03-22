// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IERC6672.sol";

contract ERC6672 is ERC721, IERC6672 {
    mapping(address => mapping(uint256 => mapping(bytes32 => bool))) redemptionStatus;
    mapping(address => mapping(uint256 => mapping(bytes32 => string))) public memos;
    mapping(address => mapping(uint256 => bytes32[])) redemptions;

    constructor() ERC721("MultiRedeemableNFT", "mrNFT") {}

    function isRedeemed(address _operator, bytes32 _redemptionId, uint256 _tokenId) external view returns (bool) {
        return _isRedeemed(_operator, _redemptionId, _tokenId);
    }

    function getRedemptionIds(address _operator, uint256 _tokenId) external view returns (bytes32[] memory) {
        require(redemptions[_operator][_tokenId].length > 0, "ERC6672: token doesn't have any redemptions.");
        return redemptions[_operator][_tokenId];
    }
    
    function redeem(bytes32 _redemptionId, uint256 _tokenId, string memory _memo) external {
        address _operator = msg.sender;
        require(!_isRedeemed(_operator, _redemptionId, _tokenId), "ERC6672: token already redeemed.");
        _update(_operator, _redemptionId, _tokenId, _memo, true);
        redemptions[_operator][_tokenId].push(_redemptionId);
    }

    function cancel(bytes32 _redemptionId, uint256 _tokenId, string memory _memo) external {
        address _operator = msg.sender;
        require(_isRedeemed(_operator, _redemptionId, _tokenId), "ERC6672: token doesn't redeemed.");
        _update(_operator, _redemptionId, _tokenId, _memo, false);
        _removeRedemption(_operator, _redemptionId, _tokenId);
    }

    function _isRedeemed(address _operator, bytes32 _redemptionId, uint256 _tokenId) internal view returns (bool) {
        require(_exists(_tokenId), "ERC6672: token doesn't exists.");
        return redemptionStatus[_operator][_tokenId][_redemptionId];
    }

    function _update(address _operator, bytes32 _redemptionId, uint256 _tokenId, string memory _memo, bool isRedeemed_) internal {
        redemptionStatus[_operator][_tokenId][_redemptionId] = isRedeemed_;
        memos[_operator][_tokenId][_redemptionId] = _memo;
    }

    function _removeRedemption(address _operator, bytes32 _redemptionId, uint256 _tokenId) internal {
        bytes32[] storage _redemptions = redemptions[_operator][_tokenId];
        for (uint i = 0; i < _redemptions.length; i++) {
            if (_redemptions[i] == _redemptionId) {
                if (i == _redemptions.length - 1) {
                    _redemptions.pop();
                } else {
                    for (uint j = 0; j < _redemptions.length - 1; j++) {
                        _redemptions[j] = _redemptions[j+1];
                    }
                }
                redemptions[_operator][_tokenId] = _redemptions;
                return;
            }
        }
    }
}