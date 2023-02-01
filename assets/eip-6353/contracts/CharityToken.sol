// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "./ERC20Charity.sol";

/**
*@title ERC720 charity Token
*@dev Extension of ERC720 Token that can be partially donated to a charity project
*
*This extensions keeps track of donations to charity addresses. The  whitelisted adress are from a another contract (Reserve)
 */

contract CharityToken is ERC20Charity{
    constructor() ERC20("TestToken", "TST") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    /** @dev Creates `amount` tokens and assigns them to `to`, increasing
     * the total supply.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     *
     * @param to The address to assign the amount to.
     * @param amount The amount of token to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function selfmint() public {
        _mint(msg.sender, 100 * 10 ** decimals());
    }
    
    
    //Test support for ERC-Charity
    bytes4 private constant _INTERFACE_ID_ERC_CHARITY = type(IERC20charity).interfaceId; // 0x557512b6
    //bytes4 private constant _INTERFACE_ID_ERCcharity =type(IERC165).interfaceId; // ERC165S
    function checkInterface(address testContract) external view returns (bool) {
    (bool success) = IERC165(testContract).supportsInterface(_INTERFACE_ID_ERC_CHARITY);
    return success;
    }

    /*function InterfaceId() external returns (bytes4) {
    bytes4 _INTERFACE_ID = type(IERC20charity).interfaceId;
    return _INTERFACE_ID ;
    }*/

}
