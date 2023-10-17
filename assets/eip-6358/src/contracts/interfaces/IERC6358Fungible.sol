// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IERC6358.sol";
import "./IERC6358Application.sol";

/**
 * @notice Interface of the omniverse fungible token, which inherits {IERC6358}
 */
interface IERC6358Fungible is IERC6358, IERC6358Application {
    /**
     * @notice Get the omniverse balance of a user `_pk`
     * @param _pk Omniverse account to be queried
     * @return Returns the omniverse balance of a user `_pk`
     */
    function omniverseBalanceOf(bytes calldata _pk) external view returns (uint256);
}