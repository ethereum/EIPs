// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/interfaces/IERC165.sol";

/// @title Interface for IERC5827 contracts
/// @notice Please see https://eips.ethereum.org/EIPS/eip-5827 for more details on the goals of this interface
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IERC5827 is IERC20, IERC165 {
    /// Note: the ERC-165 identifier for this interface is 0x93cd7af6.
    /// 0x93cd7af6 ===
    ///   bytes4(keccak256('approveRenewable(address,uint256,uint256)')) ^
    ///   bytes4(keccak256('renewableAllowance(address,address)')) ^
    ///   bytes4(keccak256('approve(address,uint256)') ^
    ///   bytes4(keccak256('transferFrom(address,address,uint256)') ^
    ///   bytes4(keccak256('allowance(address,address)') ^

    ///   @dev Thrown when there available allowance is lesser than transfer amount
    ///   @param available Allowance available, 0 if unset
    error InsufficientRenewableAllowance(uint256 available);

    /// @notice Emitted when a new renewable allowance is set.
    /// @param _owner owner of token
    /// @param _spender allowed spender of token
    /// @param _value   initial and maximum allowance given to spender
    /// @param _recoveryRate recovery amount per second
    event RenewableApproval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value,
        uint256 _recoveryRate
    );

    /// @notice Grants an allowance of `_value` to `_spender` initially, which recovers over time based on `_recoveryRate` up to a limit of `_value`.
    /// SHOULD throw when `_recoveryRate` is larger than `_value`.
    /// MUST emit `RenewableApproval` event.
    /// @param _spender allowed spender of token
    /// @param _value   initial and maximum allowance given to spender
    /// @param _recoveryRate recovery amount per second
    function approveRenewable(
        address _spender,
        uint256 _value,
        uint256 _recoveryRate
    ) external returns (bool success);

    /// @notice Returns approved max amount and recovery rate.
    /// @return amount initial and maximum allowance given to spender
    /// @return recoveryRate recovery amount per second
    function renewableAllowance(
        address _owner,
        address _spender
    ) external view returns (uint256 amount, uint256 recoveryRate);

    /// Overridden EIP-20 functions

    /// @notice Grants a (non-increasing) allowance of _value to _spender.
    /// MUST clear set _recoveryRate to 0 on the corresponding renewable allowance, if any.
    /// @param _spender allowed spender of token
    /// @param _value   allowance given to spender
    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    /// @notice Moves `amount` tokens from `from` to `to` using the
    /// allowance mechanism. `amount` is then deducted from the caller's
    /// allowance factoring in recovery rate logic.
    /// SHOULD throw when there is insufficient allowance
    /// @param from token owner address
    /// @param to token recipient
    /// @param amount amount of token to transfer
    /// @return success True if the function is successful, false if otherwise
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success);

    /// @notice Returns amounts spendable by `_spender`.
    /// @param _owner Address of the owner
    /// @param _spender spender of token
    /// @return remaining allowance at the current point in time
    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);
}
