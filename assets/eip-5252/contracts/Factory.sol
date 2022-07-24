// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Vault.sol";
import "./libraries/CloneFactory.sol";
import "./interfaces/IVaultFactory.sol";

contract VaultFactory is AccessControl, IVaultFactory {
  // Vaults
  address[] public allVaults;
  /// Address of uniswapv2 factory
  address public override v2Factory;
  /// Address of cdp nft registry
  address public override v1;
  /// Address of Wrapped Ether
  address public override WETH;
  /// Address of manager
  address public override manager;
  /// version number of impl
  uint32 version;
  /// address of vault impl
  address public impl;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _createImpl();
  }

  /// Vault can issue stablecoin, it just manages the position
  function createVault(
    address collateral_,
    address debt_,
    uint256 amount_,
    address recipient
  ) external override returns (address vault, uint256 id) {
    require(msg.sender == manager, "VaultFactory: IA");
    uint256 gIndex = allVaultsLength();
    address proxy = CloneFactory._createClone(impl);
    IVault(proxy).initialize(
      manager,
      gIndex,
      collateral_,
      debt_,
      v1,
      amount_,
      v2Factory,
      WETH
    );
    allVaults.push(proxy);
    IV1(v1).mint(recipient);
    return (proxy, gIndex);
  }

  // Set immutable, consistent, one rule for vault implementation
  function _createImpl() internal {
    address addr;
    bytes memory bytecode = type(Vault).creationCode;
    bytes32 salt = keccak256(abi.encodePacked("vault", version));
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
    address v1_,
    address v2Factory_,
    address weth_,
    address manager_
  ) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA"); // Invalid Access
    v1 = v1_;
    v2Factory = v2Factory_;
    WETH = weth_;
    manager = manager_;
  } 

  function getVault(uint256 vaultId_) external view override returns (address) {
    return allVaults[vaultId_];
  }

  function vaultCodeHash() external pure override returns (bytes32 vaultCode) {
    return
      keccak256(hex"3d602d80600a3d3981f3");
  }

  function allVaultsLength() public view returns (uint256) {
    return allVaults.length;
  }
}
