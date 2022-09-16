// SPDX-License-Identifier: CC0-1.0
// EPSProxy Contracts v1.7.0 (epsproxy/contracts/Proxiable.sol)

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@epsproxy/contracts/EPS.sol";

/**
 * @dev Contract module which allows children to implement calls to the EPS
 * proxy registry
 */

abstract contract Proxiable is Context {
  
  EPS eps; // Address for the relevant chain passed in on the constructor.

  /**
  * @dev Constructor initialises the register contract object
  */
  constructor(
    address _epsRegisterAddress
  ) {
    eps = EPS(_epsRegisterAddress); 
  }

  /**
  * @dev Returns the proxied address details (nominator and delivery address) for a passed proxy address  
  */
  function getAddresses(address _receivedAddress) internal view returns (address nominator, address delivery, bool isProxied) {
    return (eps.getAddresses(_receivedAddress));
  }

  /**
  * @dev Returns true if this is currently a proxy address (i.e. has an entry that isn't expired):
  */
  function proxyRecordExists(address _receivedAddress) internal view returns (bool isProxied) {
    return (eps.proxyRecordExists(_receivedAddress));
  }
 
  /**
  * @dev Returns an ERC20 token balance for the nominator, if a proxy record exists, or for the address
  * passed in if no proxy record exists.
  */
  function ERC20BalanceOfNominator(address _receivedAddress, address tokenContract) internal virtual view returns (uint256 _tokenBalance){
    address nominator;
    address delivery;
    bool isProxied;
    (nominator, delivery, isProxied) = getAddresses(_receivedAddress);   
    return IERC20(tokenContract).balanceOf(nominator);
  }

  /**
  * @dev Returns an ERC20 token balance for the nominator, if a proxy record exists, or for the address
  * passed in if no proxy record exists, IF we have been passed a bool indicating
  * that a proxied address is in use. This function should be used in conjunction with an off-chain call
  * to proxyRecordExists that determines if a proxy address is in use, which is then passed in on the call 
  * to the contract inheriting this method. This saves gas for anyone who is NOT using a proxy as we do not needlessly check for proxy details.
  */
  function ERC20BalanceOfNominatorSwitched(address _receivedAddress, address _tokenContract, bool _isProxied) internal virtual view returns (uint256 _tokenBalance){
    if (_isProxied) {
      return ERC20BalanceOfNominator(_receivedAddress, _tokenContract);
    }
    else {
      return IERC20(_tokenContract).balanceOf(_receivedAddress);
    }    
  }

  /**
  * @dev Returns an ERC721 token balance for the nominator, if a proxy record exists, or for the address
  * passed in if no proxy record exists.
  */
  function ERC721BalanceOfNominator(address _proxy, address tokenContract) internal virtual view returns (uint256 _tokenBalance){
    address nominator;
    address delivery;
    bool isProxied;
    (nominator, delivery, isProxied) = getAddresses(_proxy);   
    return IERC721(tokenContract).balanceOf(nominator);
  }

  /**
  * @dev Returns an ERC721 token balance for the nominator, if a proxy record exists, or for the address
  * passed in if no proxy record exists, IF we have been passed a bool indicating
  * that a proxied address is in use. This function should be used in conjunction with an off-chain call
  * to proxyRecordExists that determines if a proxy address is in use, which is then passed in on the call 
  * to the contract inheriting this method . This saves gas for anyone who is NOT using a proxy as we do not needlessly check for proxy details.
  */
  function ERC721BalanceOfNominatorSwitched(address _receivedAddress, address _tokenContract, bool _isProxied) internal virtual view returns (uint256 _tokenBalance){
    if (_isProxied) {
      return ERC721BalanceOfNominator(_receivedAddress, _tokenContract);
    }
    else {
      return IERC721(_tokenContract).balanceOf(_receivedAddress);
    }    
  }
}