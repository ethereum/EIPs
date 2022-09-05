// SPDX-License-Identifier: CC0-1.0
// EPSProxy Contracts v1.8.0 (epsproxy/contracts/examples/ERC721Proxied.sol)

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@epsproxy/contracts/Proxiable.sol";

/**
 * @dev Contract module which allows children to implement proxied delivery
 * on minting calls
 */
abstract contract ERC721Proxied is Context, ERC721, Proxiable {

  constructor(
    address _epsRegisterAddress,
    string memory _name,
    string memory _symbol
  ) Proxiable(_epsRegisterAddress) 
    ERC721("_name", "_symbol") 
  { 
  }

  /**
  * @dev Returns the proxied address details (nominator address, delivery address) for a passed proxy address.  
  * Call this to view the details for any given proxy address. 
  */
  function _getAddresses(address _receivedAddress) internal virtual view returns (address _nominator, address _delivery, bool _isProxied){
    return (getAddresses(_receivedAddress));
  }

  /**
  * @dev Returns if a given address is a proxy or not:
  */
  function _proxyRecordExists(address _receivedAddress) internal virtual view returns (bool _isProxied){
    return (proxyRecordExists(_receivedAddress));
  }

  /**
  * @dev call safemint after determining the delivery address.
  */
  function _safeMintProxied(address _to, uint256 _tokenId) internal virtual {
    address nominator;
    address delivery;
    bool isProxied;
    (nominator, delivery, isProxied) = getAddresses(_to);
    _safeMint(delivery, _tokenId);
  }

  /**
  * @dev call safemint after determining the delivery address IF we have been passed a bool indicating
  * that a proxied address is in use. This function should be used in conjunction with an off-chain call
  * to _proxyRecordExists that determines if a proxy address is in use. This saves gas for anyone who is
  * NOT using a proxy as we do not needlessly check for proxy details.
  */
  function _safeMintProxiedSwitch(address _to, uint256 _tokenId, bool _isProxied) internal virtual {
    if (_isProxied) {
      _safeMintProxied(_to, _tokenId);
    }
    else {
      _safeMint(_to, _tokenId);
    }
  }
}