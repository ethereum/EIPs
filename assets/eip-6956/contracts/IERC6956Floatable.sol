// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "./IERC6956.sol";

/**
 * @title Floatable Asset-Bound NFT
 * @notice A floatable Asset-Bound NFT can (temporarily) be transferred without attestation
 * @dev See https://eips.ethereum.org/EIPS/eip-6956
 *      Note: The ERC-165 identifier for this interface is 0xf82773f7
 */
interface IERC6956Floatable is IERC6956 {
    enum FloatState {
        Default, // 0, inherits from floatAll
        Floating, // 1
        Anchored // 2
    }

    /// @notice Indicates that an anchor-specific floating state changed
    event FloatingStateChange(bytes32 indexed anchor, uint256 indexed tokenId, FloatState isFloating, address operator);
    /// @notice Emits when FloatingAuthorization is changed.
    event FloatingAuthorizationChange(Authorization startAuthorization, Authorization stopAuthorization, address maintainer);
    /// @notice Emits, when the default floating state is changed
    event FloatingAllStateChange(bool areFloating, address operator);

    /// @notice Indicates whether an anchored token is floating, namely can be transferred without attestation
    function floating(bytes32 anchor) external view returns (bool);
    
    /// @notice Indicates whether any of OWNER, ISSUER, (ASSET) is allowed to start floating
    function floatStartAuthorization() external view returns (Authorization canStartFloating);
    
    /// @notice Indicates whether any of OWNER, ISSUER, (ASSET) is allowed to stop floating
    function floatStopAuthorization() external view returns (Authorization canStartFloating);

    /**
     * @notice Allows to override or reset to floatAll-behavior per anchor
     * @dev Must throw when newState == Floating and floatStartAuthorization does not authorize msg.sender
     * @dev Must throw when newState == Anchored and floatStopAuthorization does not authorize msg.sender
     * @param anchor The anchor, whose anchored token shall override default behavior
     * @param newState Override-State. If set to Default, the anchor will behave like floatAll
     */
    function float(bytes32 anchor, FloatState newState) external;    
}