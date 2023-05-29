// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC6786.sol";
import "./utils/IERC2981.sol";

contract ERC6786 is IERC6786, ERC165 {

    //Mapping from token (address and id) to the amount of paid royalties
    mapping(address => mapping(uint256 => uint256)) private _paidRoyalties;

    /*
     *     bytes4(keccak256('payRoyalties(address,uint256)')) == 0xf511f0e9
     *     bytes4(keccak256('getPaidRoyalties(address,uint256)')) == 0xd02ad759
     *
     *     => 0xf511f0e9 ^ 0xd02ad759 == 0x253b27b0
     */
    bytes4 private constant _INTERFACE_ID_ERC6786 = 0x253b27b0;

    /*
     * bytes4(keccak256('royaltyInfo(uint256,uint256)')) == 0x2a55205a
     */
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// @notice This is thrown when there is no creator related information
    /// @param tokenAddress -> the address of the contract
    /// @param tokenId -> the id of the NFT
    error CreatorError(address tokenAddress, uint256 tokenId);

    /// @notice This is thrown when the payment fails
    /// @param creator -> the address of the creator
    /// @param amount -> the amount to pay
    error PaymentError(address creator, uint256 amount);

    function checkRoyalties(address _contract) internal view returns (bool) {
        (bool success) = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
        interfaceId == type(IERC6786).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function payRoyalties(address tokenAddress, uint256 tokenId) external override payable {
        if (!checkRoyalties(tokenAddress)) {
            revert CreatorError(tokenAddress, tokenId);
        }
        (address creator,) = IERC2981(tokenAddress).royaltyInfo(tokenId, 0);
        (bool success,) = payable(creator).call{value : msg.value}("");
        if(!success) {
            revert PaymentError(creator, msg.value);
        }
        _paidRoyalties[tokenAddress][tokenId] += msg.value;

        emit RoyaltiesPaid(tokenAddress, tokenId, msg.value);
    }

    function getPaidRoyalties(address tokenAddress, uint256 tokenId) external view override returns (uint256) {
        return _paidRoyalties[tokenAddress][tokenId];
    }
}
