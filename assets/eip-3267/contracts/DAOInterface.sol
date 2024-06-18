// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.7.1;

/// @notice The "DAO plugin" interface.
/// @author Victor Porton
/// @notice Not audited, not enough tested.
interface DAOInterface {
    /// Check if `msg.sender` is an attorney allowed to restore a given account.
    function checkAllowedRestoreAccount(address _oldAccount, address _newAccount) external;

    /// Check if `msg.sender` is an attorney allowed to unrestore a given account.
    function checkAllowedUnrestoreAccount(address _oldAccount, address _newAccount) external;
}
