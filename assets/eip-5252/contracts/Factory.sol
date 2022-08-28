// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Finance.sol";
import "./libraries/CloneFactory.sol";
import "./interfaces/IFactory.sol";

contract Factory is AccessControl, IFactory {
    // Vaults
    address[] public allFinances;
    /// Address of cdp nft registry
    address public override abt;
    /// Address of Wrapped Ether
    address public override WETH;
    /// Address of manager
    address public override manager;
    /// version number of impl
    uint256 version;
    /// address of vault impl
    address public impl;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _createImpl();
    }

    /// Vault can issue stablecoin, it just manages the position
    function createFinance(
        address weth_,
        uint256 amount_,
        address recipient
    ) external override returns (address vault, uint256 id) {
        require(msg.sender == manager, "Factory: IA");
        uint256 gIndex = allFinancesLength();
        address proxy = CloneFactory._createClone(impl);
        IFinance(proxy).initialize(manager, gIndex, abt, amount_, weth_);
        allFinances.push(proxy);
        IABT(abt).mint(recipient);
        return (proxy, gIndex);
    }

    // Set immutable, consistent, one rule for vault implementation
    function _createImpl() internal {
        address addr;
        bytes memory bytecode = type(Finance).creationCode;
        bytes32 salt = keccak256(abi.encodePacked("finance", version));
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        impl = addr;
    }

    function isClone(address vault) external view returns (bool cloned) {
        cloned = CloneFactory._isClone(impl, vault);
    }

    function initialize(
        address abt_,
        address weth_,
        address manager_,
        uint256 version_
    ) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
        abt = abt_;
        WETH = weth_;
        manager = manager_;
        version = version_;
    }

    function getFinance(uint256 financeId_)
        external
        view
        override
        returns (address)
    {
        return allFinances[financeId_];
    }

    function financeCodeHash()
        external
        pure
        override
        returns (bytes32 vaultCode)
    {
        return keccak256(hex"3d602d80600a3d3981f3");
    }

    function allFinancesLength() public view returns (uint256) {
        return allFinances.length;
    }
}
