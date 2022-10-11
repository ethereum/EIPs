// SPDX-License-Identifier: CC0-1.0
// EPSProxy Contracts v1.8.0 (epsproxy/contracts/examples/ERC20Proxied.sol)

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@epsproxy/contracts/Proxiable.sol";

/**
 * @dev Contract module which allows children to implement proxied delivery
 * on minting calls
 */
abstract contract ERC20Proxied is Context, ERC20, Proxiable {

  /**
  * @dev call mint after determining the delivery address.
  */
  function _mintProxied(address _account, uint256 _amount) internal virtual {
    address nominator;
    address delivery;
    bool isProxied;
    (nominator, delivery, isProxied) = getAddresses(_account);
    _mint(delivery, _amount);
  }

  /**
  * @dev call mint after determining the delivery address IF we have been passed a bool indicating
  * that a proxied address is in use. This function should be used in conjunction with an off-chain call
  * to _proxyRecordExists that determines if a proxy address is in use. This saves gas for anyone who is
  * NOT using a proxy as we do not needlessly check for proxy details.
  */
  function _MintProxiedSwitch(address _account, uint256 _amount, bool _isProxied) internal virtual {
    if (_isProxied) {
      _mintProxied(_account, _amount);
    }
    else {
      _mint(_account, _amount);
    }
  }
}