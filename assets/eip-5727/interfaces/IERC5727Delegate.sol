// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC5727.sol";

/**
 * @title ERC5727 Soulbound Token Delegate Interface
 * @dev This extension allows delegation of issuing and revocation of tokens to an operator.
 */
interface IERC5727Delegate is IERC5727 {
    /**
     * @notice Emitted when a token issuance is delegated to an operator.
     * @param operator The owner to which the issuing right is delegated
     * @param slot The slot to issue the token in
     */
    event Delegate(address indexed operator, uint256 indexed slot);

    /**
     * @notice Emitted when a token issuance is revoked from an operator.
     * @param operator The owner to which the issuing right is delegated
     * @param slot The slot to issue the token in
     */
    event UnDelegate(address indexed operator, uint256 indexed slot);

    /**
     * @notice Delegate rights to `operator` for a slot.
     * @dev MUST revert if the caller does not have the right to delegate.
     *      MUST revert if the `operator` address is the zero address.
     *      MUST revert if the `slot` is not a valid slot.
     * @param operator The owner to which the issuing right is delegated
     * @param slot The slot to issue the token in
     */
    function delegate(address operator, uint256 slot) external;

    /**
     * @notice Revoke rights from `operator` for a slot.
     * @dev MUST revert if the caller does not have the right to delegate.
     *      MUST revert if the `operator` address is the zero address.
     *      MUST revert if the `slot` is not a valid slot.
     * @param operator The owner to which the issuing right is delegated
     * @param slot The slot to issue the token in
     */

    function undelegate(address operator, uint256 slot) external;

    /**
     * @notice Check if an operator has the permission to issue or revoke tokens in a slot.
     * @param operator The operator to check
     * @param slot The slot to check
     */
    function isOperatorFor(
        address operator,
        uint256 slot
    ) external view returns (bool);
}
