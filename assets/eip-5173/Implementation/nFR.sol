// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./InFR.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";
import "@prb/math/contracts/PRBMathSD59x18.sol";

import "hardhat/console.sol";

abstract contract nFR is InFR, ERC721 {

    using Address for address;

    using PRBMathUD60x18 for uint256;
    using PRBMathSD59x18 for int256;

    struct FRInfo {
        uint8 numGenerations; //  Number of generations corresponding to that Token ID
        uint256 percentOfProfit; // Percent of profit allocated for FR, scaled by 1e18
        uint256 successiveRatio; // The common ratio of successive in the geometric sequence, used for distribution calculation
        uint256 lastSoldPrice; // Last sale price in ETH mantissa
        uint256 ownerAmount; // Amount of owners the Token ID has seen
        bool isValid; // Updated by contract and signifies if an FR Info for a given Token ID is valid
    }

    struct ListInfo {
        uint256 salePrice; // ETH mantissa of the listed selling price
        address lister; // Owner/Lister of the Token
        bool isListed; // Boolean indicating whether the Token is listed or not
    }

    FRInfo private _defaultFRInfo;

    // Takes Token ID and returns corresponding FR Info
    mapping(uint256 => FRInfo) private _tokenFRInfo;

    // Takes Token ID and returns the addresses currently in the FR cycle
    mapping(uint256 => address[]) private _addressesInFR;

    // Takes Address and returns amount of ether available to address from FR payments
    mapping(address => uint256) private _allottedFR;

    // Takes Token ID and returns corresponding ListInfo
    mapping(uint256 => ListInfo) private _tokenListInfo;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(InFR).interfaceId || super.supportsInterface(interfaceId);
    }

    function retrieveFRInfo(uint256 tokenId) public view virtual override returns(uint8 numGenerations, uint256 percentOfProfit, uint256 successiveRatio, uint256 lastSoldPrice, uint256 ownerAmount, address[] memory addressesInFR) {
        return (_tokenFRInfo[tokenId].numGenerations, _tokenFRInfo[tokenId].percentOfProfit, _tokenFRInfo[tokenId].successiveRatio, _tokenFRInfo[tokenId].lastSoldPrice, _tokenFRInfo[tokenId].ownerAmount, _addressesInFR[tokenId]);
    }

    function retrieveListInfo(uint256 tokenId) public view virtual override returns(uint256, address, bool) {
        return (_tokenListInfo[tokenId].salePrice, _tokenListInfo[tokenId].lister, _tokenListInfo[tokenId].isListed);
    }

    function retrieveAllottedFR(address account) public view virtual override returns(uint256) {
        return _allottedFR[account];
    }

    function _transferFrom(address from, address to, uint256 tokenId, uint256 soldPrice) internal virtual {
        ERC721._transfer(from, to, tokenId);
        require(_checkERC721Received(from, to, tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");

        if (soldPrice <= _tokenFRInfo[tokenId].lastSoldPrice) { // NFT sold for a loss, meaning no FR distribution, but we still shift generations, and update price. We return ALL of the received ETH to the msg.sender as no FR chunk was needed.
            _tokenFRInfo[tokenId].lastSoldPrice = soldPrice;
            _tokenFRInfo[tokenId].ownerAmount++;
            _shiftGenerations(to, tokenId);
            (bool sent, ) = payable(_tokenListInfo[tokenId].lister).call{value: soldPrice}("");
            require(sent, "ERC5173: Failed to send msg.value to lister");
        } else {
            _distributeFR(tokenId, soldPrice);
            _tokenFRInfo[tokenId].lastSoldPrice = soldPrice;
            _tokenFRInfo[tokenId].ownerAmount++;
            _shiftGenerations(to, tokenId);
        }

        delete _tokenListInfo[tokenId];
    }

    function list(uint256 tokenId, uint256 salePrice) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC5173: list caller is not owner nor approved");

        _tokenListInfo[tokenId] = ListInfo(salePrice, _msgSender(), true);
    }

    function unlist(uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC5173: unlist caller is not owner nor approved");

        delete _tokenListInfo[tokenId];
    }

    function buy(uint256 tokenId) public virtual override payable {
        require(_tokenListInfo[tokenId].isListed == true, "Token is not listed");
        require(_tokenListInfo[tokenId].salePrice == msg.value, "salePrice and msg.value mismatch");

        _transferFrom(_tokenListInfo[tokenId].lister, _msgSender(), tokenId, _tokenListInfo[tokenId].salePrice);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        super._transfer(from, to, tokenId);

        if (_tokenListInfo[tokenId].isListed == true) {
            delete _tokenListInfo[tokenId];
        }

        _tokenFRInfo[tokenId].lastSoldPrice = 0;
        _tokenFRInfo[tokenId].ownerAmount++;
        _shiftGenerations(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        require(_defaultFRInfo.isValid, "No Default FR Info has been set");

        super._mint(to, tokenId);

        _tokenFRInfo[tokenId] = FRInfo(_defaultFRInfo.numGenerations, _defaultFRInfo.percentOfProfit, _defaultFRInfo.successiveRatio, 0, 1, true);

        _addressesInFR[tokenId].push(to);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        delete _tokenFRInfo[tokenId];
        delete _addressesInFR[tokenId];
        delete _tokenListInfo[tokenId];
    }

    function _mint(address to, uint256 tokenId, uint8 numGenerations, uint256 percentOfProfit, uint256 successiveRatio) internal virtual {
        require(numGenerations > 0 && percentOfProfit > 0 && percentOfProfit <= 1e18 && successiveRatio > 0, "Invalid Data Passed");

        ERC721._mint(to, tokenId);
        require(_checkERC721Received(address(0), to, tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");

        _tokenFRInfo[tokenId] = FRInfo(numGenerations, percentOfProfit, successiveRatio, 0, 1, true);

        _addressesInFR[tokenId].push(to);
    }

    function _distributeFR(uint256 tokenId, uint256 soldPrice) internal virtual {
        uint256 profit = soldPrice - _tokenFRInfo[tokenId].lastSoldPrice;
        uint256[] memory FR = _calculateFR(profit, _tokenFRInfo[tokenId].percentOfProfit, _tokenFRInfo[tokenId].successiveRatio, _tokenFRInfo[tokenId].ownerAmount, _tokenFRInfo[tokenId].numGenerations);

        for (uint owner = 0; owner < FR.length; owner++) {
            _allottedFR[_addressesInFR[tokenId][owner]] += FR[owner];
        }

        uint256 allocatedFR = 0;

        for (uint reward = 0; reward < FR.length; reward++) {
            allocatedFR += FR[reward];
        }

        (bool sent, ) = payable(_tokenListInfo[tokenId].lister).call{value: soldPrice - allocatedFR}("");
        require(sent, "Failed to send ETH after FR distribution to lister");

        emit FRDistributed(tokenId, soldPrice, allocatedFR);
    }

    function _shiftGenerations(address to, uint256 tokenId) internal virtual {
        if (_addressesInFR[tokenId].length < _tokenFRInfo[tokenId].numGenerations) { // We just want to push to the array
            _addressesInFR[tokenId].push(to);
        } else { // We want to remove the first element in the array and then push to the end of the array
            for (uint i = 0; i < _addressesInFR[tokenId].length-1; i++) {
                _addressesInFR[tokenId][i] = _addressesInFR[tokenId][i+1];
            }

            _addressesInFR[tokenId].pop();

            _addressesInFR[tokenId].push(to);
        }
    }

    function _setDefaultFRInfo(uint8 numGenerations, uint256 percentOfProfit, uint256 successiveRatio) internal virtual {
        require(numGenerations > 0 && percentOfProfit > 0 && percentOfProfit <= 1e18 && successiveRatio > 0, "Invalid Data Passed");

        _defaultFRInfo.numGenerations = numGenerations;
        _defaultFRInfo.percentOfProfit = percentOfProfit;
        _defaultFRInfo.successiveRatio = successiveRatio;
        _defaultFRInfo.isValid = true;
    }

    function releaseFR(address payable account) public virtual override {
        require(_allottedFR[account] > 0, "No FR Payment due");

        uint256 FRAmount = _allottedFR[account];

        _allottedFR[account] = 0;

        (bool sent, ) = account.call{value: FRAmount}("");
        require(sent, "Failed to release FR");

        emit FRClaimed(account, FRAmount);
    }

    function _calculateFR(uint256 totalProfit, uint256 buyerReward, uint256 successiveRatio, uint256 ownerAmount, uint256 windowSize) pure internal virtual returns(uint256[] memory) {
        uint256 n = Math.min(ownerAmount, windowSize);
        uint256[] memory FR = new uint256[](n);

        for (uint256 i = 1; i < n + 1; i++) {
            uint256 pi = 0;

            if (successiveRatio != 1e18) {
                int256 v1 = 1e18 - int256(successiveRatio).powu(n);
                int256 v2 = int256(successiveRatio).powu(i - 1);
                int256 v3 = int256(totalProfit).mul(int256(buyerReward));
                int256 v4 = v3.mul(1e18 - int256(successiveRatio));
                pi = uint256(v4 * v2 / v1);
            } else {
                pi = totalProfit.mul(buyerReward).div(n);
            }

            FR[n - i] = pi;
        }

        return FR;
    }

    function _checkERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

}